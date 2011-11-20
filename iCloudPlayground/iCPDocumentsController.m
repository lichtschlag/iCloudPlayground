//
//  iCPDocumentsController.m
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag on 13/Nov/11.
//  Copyright (c) 2011 Leonhard Lichtschlag. All rights reserved.
//

#import "iCPDocumentsController.h"
#import "iCPDocument.h"

// =================================================================================================================
@interface iCPDocumentsController ()
// =================================================================================================================

- (void) checkCloudAvailability;
- (void) enumerateCloudDocuments;
- (void) fileListReceived;

@end


// ===============================================================================================================
@implementation iCPDocumentsController
// ===============================================================================================================

@synthesize syncLabel;
@synthesize query;
@synthesize fileList;

static NSString *iCPDocumentCellIdentifier      = @"iCPDocumentCellIdentifier";
static NSString *iCPNoDocumentsCellIdentifier   = @"iCPNoDocumentsCellIdentifier";


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark View lifecycle
// ---------------------------------------------------------------------------------------------------------------

- (id) initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) 
    {
        // no documents known yet
        self.fileList = [NSMutableArray array];
    }
    return self;
}


- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self checkCloudAvailability];
}


- (void) viewDidUnload
{    
    [super viewDidUnload];
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self enumerateCloudDocuments];
}


- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void) viewWillDisappear:(BOOL)animated
{
}


- (void) viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    
    [self.query stopQuery];
    self.query = nil;
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
        NSAssert(cell != nil, @"Failed to load cell from nib.") ;
    }
    else
    {
        cellIdentifier = iCPDocumentCellIdentifier;
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        NSAssert(cell != nil, @"Failed to load cell from nib.") ;
        
        // Configure the cell...
		iCPDocument *document = [self.fileList objectAtIndex:indexPath.row];
        cell.textLabel.text = [document localizedName];
		UIDocumentState docState = [document documentState];
		NSMutableArray *docStateTextComponents = [NSMutableArray array];
		
		if (docState & UIDocumentStateNormal)
			[docStateTextComponents addObject:@"Open"];
		if (docState & UIDocumentStateClosed)
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
		BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:selectedDocument.fileURL];
		BOOL didOpen = [[UIApplication sharedApplication] openURL:selectedDocument.fileURL];
//        [[segue destinationViewController] setDocument:[self.fileList objectAtIndex:indexPath.row]];
		NSLog(@"%s %d %d", __PRETTY_FUNCTION__, canOpen, didOpen);

    }
}


- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // We only do deletion via swipe.
    NSAssert(editingStyle == UITableViewCellEditingStyleDelete, @"Unexpected editing.");

    // Delete the row from the data
    NSAssert([self.fileList count] != 0, @"Deletion with no items in the model.");
    [self removeDocument:self atIndex:indexPath.row];
    
    // Make a nice animation or swap to the cell with the hint text
    if ([self.fileList count] != 0)
    {
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                         withRowAnimation:UITableViewRowAnimationLeft];
    }
    else
    {
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                         withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark User Interaction
// ---------------------------------------------------------------------------------------------------------------

// Note: If you want to save a new document to the application’s iCloud container directory, it is recommended 
// that you first save it locally and then call the NSFileManager method 
// setUbiquitous:itemAtURL:destinationURL:error: to move the document file to iCloud storage. (This call could be 
// made in the completion handler of the saveToURL:forSaveOperation:completionHandler: method.) See “Moving 
// Documents to and from iCloud Storage” for further information.
//
//  When storing documents in iCloud, place them in the Documents subdirectory whenever possible. Documents inside
//  a Documents directory can be deleted individually by the user to free up space. However, everything outside 
//  that directory is treated as data and must be deleted all at once.
//
- (IBAction) addDocument:(id)sender
{
    // invent a name for the new file
    // TODO: avoid naming conflicts when the app runs again
    static int counter = 0;
    NSString* aFileName = [NSString stringWithFormat:@"Note %d", counter++];
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
                    //change the label
					//                    [[self.fileList lastObject] setValue:iCPFileStatusUploading forKey:iCPFileStatusKey];
//                    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:
//                                                            [NSIndexPath indexPathForRow:([self.fileList count] -1) inSection:0]] 
//                                          withRowAnimation:UITableViewRowAnimationFade];
                }
                else
                {
                    NSLog(@"%s error while saving", __PRETTY_FUNCTION__);
                }
                
            }];
    
	[self.fileList addObject:newDocument];

    if ([self.fileList count] == 1)
    {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] 
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else
    {
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:([self.fileList count] -1) inSection:0]] 
                              withRowAnimation:UITableViewRowAnimationFade];
    }
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
	
    [self.fileList removeObjectAtIndex:index];
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
	NSArray* queryResults = [self.query results];
	
	// TODO: avoid clearing the array
	self.fileList = [NSMutableArray array];
	
	for (NSMetadataItem* aResult in queryResults)
	{
		NSURL* fileURL = [aResult valueForAttribute:NSMetadataItemURLKey];
		[self.fileList addObject:[[iCPDocument alloc] initWithFileURL:fileURL]];
	}

	[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}


@end

