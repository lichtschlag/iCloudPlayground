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
- (void) documentStateChanged:(NSNotification *)notification;

@end


// ===============================================================================================================
@implementation iCPDocumentsController
// ===============================================================================================================

@synthesize syncLabel;
@synthesize query;
@synthesize fileList;
@synthesize previousQueryResults;

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
	
	// register for state changes
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(documentStateChanged:)
                                                 name:UIDocumentStateChangedNotification
											   object:nil];
}


- (void) viewDidUnload
{    
    [super viewDidUnload];
	
    [self.query stopQuery];
    self.query = nil;
	self.previousQueryResults = [NSMutableArray array];
	self.fileList = [NSMutableArray array];
	[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
		iCPDocument *document = [self.fileList objectAtIndex:indexPath.row];
        cell.textLabel.text = [document localizedName];
		UIDocumentState docState = [document documentState];
		NSMutableArray *docStateTextComponents = [NSMutableArray array];
		
		if (docState == UIDocumentStateNormal)	// all bits 0
			[docStateTextComponents addObject:@"Open"];
		if (docState & UIDocumentStateClosed)	// the following have one bit 1
			[docStateTextComponents addObject:@"Closed"];
		if (docState & UIDocumentStateInConflict)
			[docStateTextComponents addObject:@"Merge Conflict"];
		if (docState & UIDocumentStateSavingError)
			[docStateTextComponents addObject:@"Saving Error"];
		if (docState & UIDocumentStateEditingDisabled)
			[docStateTextComponents addObject:@"NoEdit"];
		
		cell.detailTextLabel.text = [docStateTextComponents componentsJoinedByString:@", "];
	}
	
	return cell;
}


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// this method is our chance to give the document controller some model data
	if ([[segue identifier] isEqualToString:@"editDocumentSegue"])
	{
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		iCPDocument* selectedDocument = [self.fileList objectAtIndex:indexPath.row];
		
		[[segue destinationViewController] setDocument:selectedDocument];
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
//  When storing documents in iCloud, place them in the Documents subdirectory whenever possible. Documents inside
//  a Documents directory can be deleted individually by the user to free up space. However, everything outside 
//  that directory is treated as data and must be deleted all at once.
//
- (IBAction) addDocument:(id)sender
{
    // invent a name for the new file
    static int counter = 2;
	static NSString *previousDateString = @"";
	NSString *dateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
														  dateStyle:NSDateFormatterShortStyle
														  timeStyle:NSDateFormatterMediumStyle];
	NSString* aFileName;
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
			 // TODO: defer creating the docoument in iCloud storage
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
- (IBAction) removeDocument:(id)sender atIndex:(NSInteger)index;
{
	NSURL* fileURL = [[self.fileList objectAtIndex:index] fileURL];
	
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


- (void) documentStateChanged:(NSNotification *)notification;
{
	iCPDocument	*changedDocument = notification.object;
	NSUInteger index = [self.fileList indexOfObject:changedDocument];
	if (index != NSNotFound)
		[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]]
							  withRowAnimation:UITableViewRowAnimationAutomatic];
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
        [syncLabel setText:@"iCloud is available"];
    }
    else
    {
        [syncLabel setText:@"iCloud not available. ☹"];
    }
}


- (void) enumerateCloudDocuments;
{    
    self.query = [[NSMetadataQuery alloc] init];
    [query setSearchScopes:[NSArray arrayWithObjects:NSMetadataQueryUbiquitousDocumentsScope, nil]];
    NSString* predicate = [NSString stringWithFormat:@"%%K like '*.%@'", iCPPathExtension];
    [query setPredicate:[NSPredicate predicateWithFormat:predicate, NSMetadataItemFSNameKey]];

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
	for (NSMetadataItem *aResult in [self.query results]) 
	{
		[queryResultURLs addObject:[aResult valueForAttribute:NSMetadataItemURLKey]];
	}
	
	// calculate diff between arrays to find which are new, which are to be removed
	NSMutableArray* newURLs = [queryResultURLs mutableCopy];
	NSMutableArray* removedURLs = [previousQueryResults mutableCopy];
	[newURLs removeObjectsInArray:previousQueryResults];
	[removedURLs removeObjectsInArray:queryResultURLs];

	// remove tableview entries (file is already gone, we are just updating the view)
	for (int i = 0; i < [self.fileList count]; ) 
	{
		iCPDocument *aDoc = [self.fileList objectAtIndex:i];
		if ([removedURLs containsObject:aDoc.fileURL])
		{
			NSInteger aRow = [self.fileList indexOfObject:aDoc];
			[self.fileList removeObject:aDoc];
			
			// Make a nice animation or swap to the cell with the hint text
			if ([self.fileList count] != 0)
			{
				[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:aRow inSection:0]]
									  withRowAnimation:UITableViewRowAnimationLeft];
			}
			else
			{
				[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:aRow inSection:0]]
									  withRowAnimation:UITableViewRowAnimationLeft];
			}
		}
		else
		{
			i++;
		}
	}
	
	// add tableview entries (file exists, but we have to create a new iCPDocument)
	for (NSURL *aNewURL in newURLs)
	{
		[self.fileList addObject:[[iCPDocument alloc] initWithFileURL:aNewURL]];
		
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

