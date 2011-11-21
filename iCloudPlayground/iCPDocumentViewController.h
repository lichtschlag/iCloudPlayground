//
//  iCPDocumentViewController.h
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag (leonhard@lichtschlag.net) on 20/Nov/11.
//  Copyright (c) 2011 Leonhard Lichtschlag. All rights reserved.
//

#import <UIKit/UIKit.h>

@class iCPDocument;

// ===============================================================================================================
@interface iCPDocumentViewController : UIViewController
// ===============================================================================================================

@property (retain) iCPDocument *document;
@property (weak, nonatomic) IBOutlet UITextView *textView;

- (IBAction) shareButtonClicked:(id)sender;


@end

