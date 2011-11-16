//
//  iCPSecondViewController.h
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag on 13/Nov/11.
//  Copyright (c) 2011 Leonhard Lichtschlag. All rights reserved.
//

#import <UIKit/UIKit.h>

// ===============================================================================================================
@interface iCPSecondViewController : UIViewController
// ===============================================================================================================

@property (weak, nonatomic) IBOutlet UILabel    *syncLabel;
@property (retain) NSMetadataQuery *query;
@property (retain) NSMutableArray *fileList;

@end
