//
//  iCPDocumentsController.m
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag (leonhard@lichtschlag.net) on 13/Nov/11.
//  Copyright (c) 2011 Leonhard Lichtschlag. All rights reserved.
//

#import "iCPDocumentsController.h"
#import "iCPDocumentViewController.h"
#import "iCPDocument.h"

// =================================================================================================================
@interface iCPDocumentsController ()
// =================================================================================================================

- (void) checkCloudAvailability;
- (void) enumerateCloudDocuments;
- (void) fileListReceived;
- (void) updateTimerFired:(NSTimer *)timer;

@end


// ===============================================================================================================
@implementation iCPDocumentsController
// ===============================================================================================================

@synthesize syncLabel;
@synthesize query;
@synthesize fileList;
@synthesize previousQueryResults;
@synthesize updateTimer;
@synthesize plusButton;

static NSString *iCPDocumentCellIdentifier      = @"iCPDocumentCellIdentifier";
static NSString *iCPNoDocumentsCellIdentifier   = @"iCPNoDocumentsCellIdentifier";


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark View lifecycle
// ---------------------------------------------------------------------------------------------------------------

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self checkCloudAvailability];
	
	// no documents known yet
	self.fileList = [NSMutableArray array];
	self.previousQueryResults = [NSMutableArray array];
	
	[self enumerateCloudDocuments];
	
	// add a timer that updates out for changes in the file metadata
	self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 
														target:self 
													  selector:@selector(updateTimerFired:) 
													  userInfo:nil 
													   repeats:YES];
}


- (void) viewDidUnload
{
	[self setPlusButton:nil];
	[super viewDidUnload];
	
	[self.query stopQuery];
	self.query = nil;
	self.previousQueryResults = [NSMutableArray array];
	self.fileList = [NSMutableArray array];
	[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
	
	// remove timer
	[self.updateTimer invalidate];
	self.updateTimer = nil;
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
	{
		// on iPhone, only allow normal vertical orientation
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
	} 
	else 
	{
		return YES;
	}
}


- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Table view data source and delegate
// ---------------------------------------------------------------------------------------------------------------

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    // We have only one section, containing all the documents
    return 1;
}


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// Return the number of files OR one (to show a hint that no files exist).
	return MAX(1, [self.fileList count]);
}


- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Return NO if it is just the helper text. It cannot be deleted.
	if ([self.fileList count] == 0)
	{
		return NO;
	}
	else
	{
		return YES;
	}
}


- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *cellIdentifier;
	UITableViewCell *cell;
	// dequeueReusableCellWithIdentifier: will not fail, since prototypes are in the storyboard
	
	if ([self.fileList count] == 0)
	{
		// show a hint that the list in empty
		cellIdentifier = iCPNoDocumentsCellIdentifier;
		cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		NSAssert(cell != nil, @"Failed to load cell from nib.");
	}
	else
	{
		cellIdentifier = iCPDocumentCellIdentifier;
		cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		NSAssert(cell != nil, @"Failed to load cell from nib.");
		
		// Configure the cell...
		NSMetadataItem *metadataItem = [self.fileList objectAtIndex:indexPath.row];
		cell.textLabel.text = [metadataItem valueForAttribute:NSMetadataItemDisplayNameKey];
		
		// The "conflict" property of NSFileVersion is false for the selected merged version, which is somehat unintuitively
		// It is only true if the merge is still unresolved (we should never notie this) or our object is the discarded one.
		// Instead we use the following to detect merge conflicts:
		NSNumber *test = [metadataItem valueForAttribute:NSMetadataUbiquitousItemHasUnresolvedConflictsKey];
		if ([test boolValue] == YES)
		{
			cell.detailTextLabel.text = @"Conflict while merging";
			cell.detailTextLabel.textColor = [UIColor redColor];
		}
		else
		{
			cell.detailTextLabel.text = @"No conflicts";
			cell.detailTextLabel.textColor = [UIColor lightGrayColor];
		}
	}
	
	return cell;
}


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// this method is our chance to give the document controller some model data
	if ([[segue identifier] isEqualToString:@"editDocumentSegue"])
	{
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		NSMetadataItem *selectedFile = [self.fileList objectAtIndex:indexPath.row];
		iCPDocument *selectedDocument = [[iCPDocument alloc] initWithFileURL:[selectedFile valueForAttribute:NSMetadataItemURLKey]];
		
		[(iCPDocumentViewController *)[segue destinationViewController] setDocument:selectedDocument];
	}
}


- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	// We only do deletion via swipe.
	NSAssert(editingStyle == UITableViewCellEditingStyleDelete, @"Unexpected editing.");

	// Delete the row from the data
	NSAssert([self.fileList count] != 0, @"Deletion with no items in the model.");
	
	[self removeDocument:self atIndex:indexPath.row];
}


- (void) updateTimerFired:(NSTimer *)timer;
{
	[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Document Handling
// ---------------------------------------------------------------------------------------------------------------

//	Note: If you want to save a new document to the application’s iCloud container directory, it is recommended 
//	that you first save it locally and then call the NSFileManager method 
//	setUbiquitous:itemAtURL:destinationURL:error: to move the document file to iCloud storage. (This call could be 
//	made in the completion handler of the saveToURL:forSaveOperation:completionHandler: method.) See “Moving 
//	Documents to and from iCloud Storage” for further information.
//
//	When storing documents in iCloud, place them in the Documents subdirectory whenever possible. Documents inside
//	a Documents directory can be deleted individually by the user to free up space. However, everything outside 
//	that directory is treated as data and must be deleted all at once.
//
- (IBAction) addDocument:(id)sender
{
	// invent a name for the new file
	static int counter = 2;
	static NSString *previousDateString = @"";

	// format the date manually to avoid illegal or abigious filenames (i.e., with / or :)
	// As an alternative one could use GUIDs
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"MM.dd.yy H-m"];
	NSString *dateString = [dateFormat stringFromDate:[NSDate date]];
	NSString *aFileName = @"";

	if ([dateString isEqualToString:previousDateString])
	{
		aFileName = [NSString stringWithFormat:@"%@ (%d)", dateString, counter++];
	}
	else
	{
		aFileName = [NSString stringWithFormat:@"%@", dateString];
		counter = 2;
	}
	previousDateString = dateString;
	aFileName = [aFileName stringByAppendingPathExtension:iCPPathExtension];
	
	// get the URL to save the new file to
	NSURL *folderURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
	folderURL = [folderURL URLByAppendingPathComponent:@"Documents"];
	NSURL *fileURL = [folderURL URLByAppendingPathComponent:aFileName];
	
	// initialize a document with that path
	iCPDocument *newDocument = [[iCPDocument alloc] initWithFileURL:fileURL];

	// save the document immediately
	[newDocument saveToURL:newDocument.fileURL
		  forSaveOperation:UIDocumentSaveForCreating
		 completionHandler:^(BOOL success)
	 {
		 if (success)
		 {
			 // Saving implicitly opens the file. An open document will restore the its (remotely) deleted file representation.
			 [newDocument closeWithCompletionHandler:nil];
		 }
		 else
		 {
			 NSLog(@"%s error while saving", __PRETTY_FUNCTION__);
		 }
	 }];
}


// When you delete a document from storage, your code should approximate what UIDocument does for reading and 
// writing operations. It should perform the deletion asynchronously on a background queue, and it should use 
// file coordination.
- (void) removeDocument:(id)sender atIndex:(NSInteger)index;
{
	NSURL* fileURL = [[self.fileList objectAtIndex:index] valueForAttribute:NSMetadataItemURLKey];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
	{
		NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
		[fileCoordinator coordinateWritingItemAtURL:fileURL
											options:NSFileCoordinatorWritingForDeleting
											  error:nil
										 byAccessor:^(NSURL* writingURL)
		 {
			 NSFileManager* fileManager = [[NSFileManager alloc] init];
			 [fileManager removeItemAtURL:writingURL error:nil];
		 }];
	});
}


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark cloud data
// ---------------------------------------------------------------------------------------------------------------

- (void) checkCloudAvailability;
{
	[syncLabel setText:@"Checking iCloud availablity…"];
	NSURL *returnedURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
	
	if (returnedURL)
	{
		[self.syncLabel setText:@"iCloud is available"];
		[self.plusButton setEnabled:YES];
	}
	else
	{
		[self.syncLabel setText:@"iCloud not available. ☹"];
		[self.plusButton setEnabled:NO];
	}
}


- (void) enumerateCloudDocuments;
{
	self.query = [[NSMetadataQuery alloc] init];
	[query setSearchScopes:[NSArray arrayWithObjects:NSMetadataQueryUbiquitousDocumentsScope, nil]];
	NSString* predicate = [NSString stringWithFormat:@"kMDItemFSName like '*.%@'", iCPPathExtension];
	[query setPredicate:[NSPredicate predicateWithFormat:predicate]];

	// pull a list of all the documents in the cloud
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(fileListReceived)
												 name:NSMetadataQueryDidFinishGatheringNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(fileListReceived)
												 name:NSMetadataQueryDidUpdateNotification object:nil];

	[self.query startQuery];
}


- (void) fileListReceived 
{
	// get URLs out of query results
	NSMutableArray* queryResultURLs = [NSMutableArray array];
	NSMutableDictionary *metadataItemForURL = [NSMutableDictionary dictionary];
	for (NSInteger i = 0; i < self.query.resultCount; i++)
	{
		NSMetadataItem *metadataItem = [self.query resultAtIndex:i];
		NSURL *url = [metadataItem valueForAttribute:NSMetadataItemURLKey];
		[queryResultURLs addObject:url];
		[metadataItemForURL setObject:metadataItem forKey:url];
	}
	
	// calculate diff between arrays to find which are new, which are to be removed
	NSMutableArray* newURLs = [queryResultURLs mutableCopy];
	NSMutableArray* removedURLs = [previousQueryResults mutableCopy];
	[newURLs removeObjectsInArray:previousQueryResults];
	[removedURLs removeObjectsInArray:queryResultURLs];

	// remove tableview entries (file is already gone, we are just updating the view)
	for (int i = 0; i < [self.fileList count]; ) 
	{
		NSMetadataItem *aFile = [self.fileList objectAtIndex:i];
		if ([removedURLs containsObject:[aFile valueForAttribute:NSMetadataItemURLKey]])
		{
			[self.fileList removeObjectAtIndex:i];			
			// Make a nice animation or swap to the cell with the hint text
			if ([self.fileList count] != 0)
			{
				[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]]
									  withRowAnimation:UITableViewRowAnimationLeft];
			}
			else
			{
				[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]]
									  withRowAnimation:UITableViewRowAnimationLeft];
			}
		}
		else
		{
			i++;
		}
	}
	
	// add tableview entries (file exists, but we have to create a new NSFileVersion to track it)
	for (NSURL *aNewURL in newURLs)
	{
		
		[self.fileList addObject:[metadataItemForURL objectForKey:aNewURL]];
		
		if ([self.fileList count] != 1)
		{
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:([self.fileList count] -1) inSection:0]]
								  withRowAnimation:UITableViewRowAnimationLeft];
		}
		else
		{
			[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:([self.fileList count] -1) inSection:0]]
								  withRowAnimation:UITableViewRowAnimationRight];
		}
	}

	self.previousQueryResults = queryResultURLs;
}


@end

