//
//  iCPMergeController.h
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag on 5/Mar/12.
//  Copyright (c) 2012 Media Computing Group, RWTH Aachen University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class iCPDocument;

// ===============================================================================================================
@interface iCPMergeController : UIViewController
// ===============================================================================================================

@property (retain) iCPDocument *currentDocument;
@property (weak, nonatomic) IBOutlet UITextView *currentContents;
@property (weak, nonatomic) IBOutlet UITextView *alternateContents;
@property (weak, nonatomic) IBOutlet UILabel *currentVersionInfo;
@property (weak, nonatomic) IBOutlet UILabel *alternateVersionInfo;

- (IBAction) chooseAlternateVersion:(id) sender;
- (IBAction) chooseCurrentVersion:(id) sender;


@end

