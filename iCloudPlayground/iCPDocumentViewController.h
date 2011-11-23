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
@interface iCPDocumentViewController : UIViewController <UITextViewDelegate>
// ===============================================================================================================

@property (retain) iCPDocument *document;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *doneButton;

- (IBAction) shareButtonPressed:(id)sender;
- (IBAction) doneButtonPressed:(id)sender;


@end

