//
//  iCPSecondViewController.m
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag on 13/Nov/11.
//  Copyright (c) 2011 Leonhard Lichtschlag. All rights reserved.
//

#import "iCPSecondViewController.h"

// =================================================================================================================
@interface iCPSecondViewController ()
// =================================================================================================================

- (void) checkCloudAvailability;
- (void) enumerateCloudDocuments;
- (void) fileListReceived ;

@end


// ===============================================================================================================
@implementation iCPSecondViewController
// ===============================================================================================================

@synthesize syncLabel;
@synthesize query;
@synthesize fileList;


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark View lifecycle
// ---------------------------------------------------------------------------------------------------------------

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self checkCloudAvailability];
	[self enumerateCloudDocuments];
}


- (void) viewDidUnload
{
    [super viewDidUnload];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.fileList = nil;
    [self.query stopQuery];
    self.query = nil;
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}


- (void) viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
    {
        // on iPhone I only allow normal vertical orientation
        return (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
    } 
    else 
    {
        return YES;
    }
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
        NSLog(@"%s %@", __PRETTY_FUNCTION__, returnedURL);
        [syncLabel setText:@"iCloud is available"];
    }
    else
    {
        [syncLabel setText:@"iCloud not available. ☹"];
    }
}


- (void) enumerateCloudDocuments;
{    
    NSLog(@"%s", __PRETTY_FUNCTION__);

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
    NSLog(@"%s", __PRETTY_FUNCTION__);

    self.fileList = [NSMutableArray array];

    //retain current selection
//    NSString* selectedFileName  = nil;
//    NSInteger newSelectionRow   = [self.tableView indexPathForSelectedRow].row;
    
//    if (newSelectionRow != NSNotFound) 
//    {
//        selectedFileName = [[_fileList objectAtIndex:newSelectionRow] fileName];
//    }
    
    NSArray* queryResults = [self.query results];
    for (NSMetadataItem* aResult in queryResults) 
    {        
        NSString* fileName = [aResult valueForAttribute:NSMetadataItemFSNameKey];
        //restore selection
//        if (selectedFileName && [selectedFileName isEqualToString:fileName]) 
//        {
//            newSelectionRow = [_fileList count];
//        }
        
        [self.fileList addObject:[aResult valueForAttribute:NSMetadataItemURLKey]];
    }
    
//    [self.tableView reloadData];
//    if (newSelectionRow != NSNotFound) 
//    {
//        NSIndexPath* selectionPath = [NSIndexPath indexPathForRow:newSelectionRow inSection:0];
//        [self.tableView selectRowAtIndexPath:selectionPath animated:NO scrollPosition:UITableViewScrollPositionNone];
//    }
    
}
@end

