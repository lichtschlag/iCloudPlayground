//
//  iCPFirstViewController.m
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag (leonhard@lichtschlag.net) on 13/Nov/11.
//  Copyright (c) 2011 Leonhard Lichtschlag. All rights reserved.
//

#import "iCPFirstViewController.h"

NSString *const kiCPJanKey          = @"kiCPJanKey";
NSString *const kiCPExamKey         = @"kiCPExamKey";
NSString *const kiCPCorrectionKey   = @"kiCPCorrectionKey";


// ===============================================================================================================
@interface iCPFirstViewController ()
// ===============================================================================================================

- (void) pullCloudData;
- (void) cloudDataChanged:(NSNotification *)receivedNotification;

@end


// ===============================================================================================================
@implementation iCPFirstViewController
// ===============================================================================================================

@synthesize syncLabel;


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark View lifecycle
// ---------------------------------------------------------------------------------------------------------------

- (void) viewDidLoad
{
    [super viewDidLoad];
}


- (void) viewDidUnload
{
    [self setJanToggle:nil];
    [self setExamToggle:nil];
    [self setCorrectionToggle:nil];

    [self setSyncLabel:nil];
    [super viewDidUnload];
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // subscribe to changes in the cloud store
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(cloudDataChanged:)
                                                 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification 
                                               object:[NSUbiquitousKeyValueStore defaultStore]];
}


- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self pullCloudData];
}


- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}


- (void) viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
	[super viewDidDisappear:animated];
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
#pragma mark Cloud Interaction
// ---------------------------------------------------------------------------------------------------------------

- (void) pullCloudData
{
    [syncLabel setText:@"Pulling Cloud data…"];
    BOOL success = [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    
    if (success)
    {
        [syncLabel setText:[NSString stringWithFormat:@"Sync on %@", [NSDateFormatter localizedStringFromDate:[NSDate date] 
                                                                                                    dateStyle:NSDateFormatterLongStyle 
                                                                                                    timeStyle:NSDateFormatterMediumStyle]]];
        [self.janToggle setEnabled:YES];
        [self.examToggle setEnabled:YES];
        [self.correctionToggle setEnabled:YES];
        
        // pull all keys from the store, no matter if they have changed or not.
        [self.janToggle setOn:[[NSUbiquitousKeyValueStore defaultStore] boolForKey:kiCPJanKey]];
        [self.examToggle setOn:[[NSUbiquitousKeyValueStore defaultStore] boolForKey:kiCPExamKey]];
        [self.correctionToggle setOn:[[NSUbiquitousKeyValueStore defaultStore] boolForKey:kiCPCorrectionKey]];
    }
    else
    {
        [syncLabel setText:@"Failed to connect to iCloud"];
    }
}


- (void) cloudDataChanged:(NSNotification *)receivedNotification
{
    // The user info dictionary can contain the NSUbiquitousKeyValueStoreChangedKeysKey and NSUbiquitousKeyValueStoreChangeReasonKey keys, 
    // which indicate the keys that changed and the reason they changed.
    // NSDictionary    *changedKeys   = [[receivedNotification userInfo] valueForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
    int reason = [[[receivedNotification userInfo] valueForKey:NSUbiquitousKeyValueStoreChangeReasonKey] intValue];
 
    NSAssert(reason != NSUbiquitousKeyValueStoreQuotaViolationChange, @"iCloud storage exceeded");
    
    if (reason == NSUbiquitousKeyValueStoreInitialSyncChange)
    {
        // This should be fired when our app is launched the first time or when the user changed his iCloud account.
        NSLog(@"%s Populating local data from iCloud data.", __PRETTY_FUNCTION__);
    }
    if (reason == NSUbiquitousKeyValueStoreServerChange)
    {
        // Another device ran our app and and changed the value since our last sync. 
        NSLog(@"%s Remote key change.", __PRETTY_FUNCTION__);
    }
        
    // pull all keys from the store, no matter if they have changed or not.
    [self.janToggle setOn:[[NSUbiquitousKeyValueStore defaultStore] boolForKey:kiCPJanKey]];
    [self.examToggle setOn:[[NSUbiquitousKeyValueStore defaultStore] boolForKey:kiCPExamKey]];
    [self.correctionToggle setOn:[[NSUbiquitousKeyValueStore defaultStore] boolForKey:kiCPCorrectionKey]];
    
    [syncLabel setText:[NSString stringWithFormat:@"Sync on %@", [NSDateFormatter localizedStringFromDate:[NSDate date] 
                                                                                                dateStyle:NSDateFormatterLongStyle 
                                                                                                timeStyle:NSDateFormatterMediumStyle]]];
}


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Buttons clicked by the user
// ---------------------------------------------------------------------------------------------------------------

@synthesize janToggle;
@synthesize examToggle;
@synthesize correctionToggle;


- (IBAction) janToggleChanged:(id)sender 
{
    // send data to iCloud
    [[NSUbiquitousKeyValueStore defaultStore] setBool:[sender isOn] forKey:kiCPJanKey];
}


- (IBAction) examToggleChanged:(id)sender 
{
    // send data to iCloud
    [[NSUbiquitousKeyValueStore defaultStore] setBool:[sender isOn] forKey:kiCPExamKey];
}


- (IBAction) correctionToggleChanged:(id)sender 
{
    // send data to iCloud
    [[NSUbiquitousKeyValueStore defaultStore] setBool:[sender isOn] forKey:kiCPCorrectionKey];
}


@end

