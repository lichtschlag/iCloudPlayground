//
//  iCPMergeController.m
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag on 5/Mar/12.
//  Copyright (c) 2012 Media Computing Group, RWTH Aachen University. All rights reserved.
//

#import "iCPMergeController.h"
#import "iCPDocument.h"


// ===============================================================================================================
@interface iCPMergeController ()
// ===============================================================================================================

@end


// ===============================================================================================================
@implementation iCPMergeController
// ===============================================================================================================

@synthesize document;


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark View Life Cycle
// ---------------------------------------------------------------------------------------------------------------

- (void) viewDidLoad
{
    [super viewDidLoad];

}


- (void) viewDidUnload
{
    [super viewDidUnload];
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Interaction
// ---------------------------------------------------------------------------------------------------------------




@end

