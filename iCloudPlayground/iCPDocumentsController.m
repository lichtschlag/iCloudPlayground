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


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark View lifecycle
// ---------------------------------------------------------------------------------------------------------------

- (id)initWithStyle:(UITableViewStyle)style
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
    // We have only one section, containing all the files
    return 1;
}


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of files OR one (to show a hint that no files exist.
    return MAX(1, [self.fileList count]);
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
 (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    
     DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"Nib name" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
   
}*/


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark User Interaction
// ---------------------------------------------------------------------------------------------------------------

- (IBAction) addDocument:(id)sender
{
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [self.fileList addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Hallo.doc",   iCPFileNameKey,
                              @"",    iCPFileURLKey,
                              @"downloading…", iCPFileStatusKey, nil]];
    [self.tableView reloadData];
}


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark cloud data
// ---------------------------------------------------------------------------------------------------------------

- (void) checkCloudAvailability;
{
    [syncLabel setText:@"Checking iCloud availablity"];
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
                                                                            @"unknown", iCPFileStatusKey, nil]];
    }
    
  
    [self.tableView reloadData];
    NSLog(@"%s %@", __PRETTY_FUNCTION__, self.fileList);
}

@end

