//
//  iCPFirstViewController.h
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag (leonhard@lichtschlag.net) on 13/Nov/11.
//  Copyright (c) 2011 Leonhard Lichtschlag. All rights reserved.
//

#import <UIKit/UIKit.h>

// ===============================================================================================================
@interface iCPFirstViewController : UIViewController
// ===============================================================================================================

@property (weak, nonatomic) IBOutlet UISwitch   *janToggle;
@property (weak, nonatomic) IBOutlet UISwitch   *examToggle;
@property (weak, nonatomic) IBOutlet UISwitch   *correctionToggle;
@property (weak, nonatomic) IBOutlet UILabel    *syncLabel;

@end
