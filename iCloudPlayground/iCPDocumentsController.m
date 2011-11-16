//
//  iCPDocumentsController.m
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag on 13/Nov/11.
//  Copyright (c) 2011 Leonhard Lichtschlag. All rights reserved.
//

#import "iCPDocumentsController.h"

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

static NSString *iCPFileNameKey     = @"iCPFileNameKey";
static NSString *iCPFileURLKey      = @"iCPFileURLKey";
static NSString *iCPFileStatusKey   = @"iCPFileStatusKey";

static NSString *iCPFileStatusSaving        = @"created and saving to disk…";
static NSString *iCPFileStatusUploading     = @"uploading to iCloud…";
static NSString *iCPFileStatusRemote        = @"discovered on iCloud server";
static NSString *iCPFileStatusDownloading   = @"downloading from iCloud…";
static NSString *iCPFileStatusSynched       = @"in sync";
static NSString *iCPFileStatusMergeError    = @"errors while merging";


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark View lifecycle
// ---------------------------------------------------------------------------------------------------------------

- (id) initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) 
    {
        // documents is an empty array
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
        // on iPhone I only allow normal vertical orientation
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
    // Return the number of files OR one (to show a hint that no files exist.
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
    
    if ([self.fileList count] == 0)
    {
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
        cell.textLabel.text = [[self.fileList objectAtIndex:indexPath.row] valueForKey:iCPFileNameKey];
        cell.detailTextLabel.text = [[self.fileList objectAtIndex:indexPath.row] valueForKey:iCPFileStatusKey];
    }
    
    return cell;
}


/*- 
 (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    
     DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"Nib name" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
   
}*/



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
                         withRowAnimation:UITableViewRowAnimationAutomatic];
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

- (IBAction) addDocument:(id)sender
{
    static int counter = 0;
    NSString* aFileName = [NSString stringWithFormat:@"Hallo %d.doc", counter++];
    [self.fileList addObject:[NSDictionary dictionaryWithObjectsAndKeys:aFileName,   iCPFileNameKey,
                                                                        @"",    iCPFileURLKey,
                                                                        iCPFileStatusSaving, iCPFileStatusKey, nil]];

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


- (IBAction) removeDocument:(id)sender atIndex:(NSInteger)index;
{
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
    
    NSLog(@"%s %@", __PRETTY_FUNCTION__, returnedURL);
}


- (void) enumerateCloudDocuments;
{    
    self.query = [[NSMetadataQuery alloc] init];
    [query setSearchScopes:[NSArray arrayWithObjects:NSMetadataQueryUbiquitousDocumentsScope, nil]];
    [query setPredicate:[NSPredicate predicateWithFormat:@"%K == '*.iCloudPlaygroundDoc'", NSMetadataItemFSNameKey]];

    // pull a list of all the documents in the cloud
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(fileListReceived)
                                                 name:NSMetadataQueryDidFinishGatheringNotification object:nil];

    [self.query startQuery];
}


- (void) fileListReceived 
{
    self.fileList = [NSMutableArray array];
    
    NSArray* queryResults = [self.query results];
    for (NSMetadataItem* aResult in queryResults) 
    {        
        NSString* fileName = [aResult valueForAttribute:NSMetadataItemFSNameKey];        
        NSString* fileURL = [aResult valueForAttribute:NSMetadataItemURLKey];
        [self.fileList addObject:[NSDictionary dictionaryWithObjectsAndKeys:fileName,   iCPFileNameKey,
                                                                            fileURL,    iCPFileURLKey,
                                                                            iCPFileStatusRemote, iCPFileStatusKey, nil]];
    }
    
  
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];

    NSLog(@"%s %@", __PRETTY_FUNCTION__, self.fileList);
}

@end

