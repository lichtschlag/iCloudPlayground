//
//  iCPDocumentViewController.m
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag (leonhard@lichtschlag.net) on 20/Nov/11.
//  Copyright (c) 2011 Leonhard Lichtschlag. All rights reserved.
//

#import "iCPDocumentViewController.h"
#import "iCPDocument.h"
#include <QuartzCore/CALayer.h>
#include <Twitter/TWTweetComposeViewController.h>

// ===============================================================================================================
@implementation iCPDocumentViewController
// ===============================================================================================================

@synthesize document;
@synthesize textView;
@synthesize progressView;
@synthesize doneButton;
@synthesize openButton;
@synthesize progressText;

// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark - View lifecycle
// ---------------------------------------------------------------------------------------------------------------

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void) viewDidLoad
{
    [super viewDidLoad];
	
	// visual style of the text layer
	[self.textView.layer setCornerRadius:10.0];
	UIColor *gray = [UIColor colorWithWhite:0.607 alpha:1.000];
	[self.textView.layer setBorderColor:[gray CGColor]];
	[self.textView.layer setBorderWidth:1.0];
	
	// visual style of the loading layer
	[self.progressView.layer setCornerRadius:10.0];
	
	// hide the done button before the user starts editing
	self.navigationItem.rightBarButtonItem = nil;

	// get contents from document
	[self.document openWithCompletionHandler:^(BOOL success)
	 {
		 if (success)
		 {
			 self.textView.text = document.contents;
			 [self.progressView removeFromSuperview];
		 }
		 else
		 {
			 NSAssert(NO, @"Failed to load document");
		 }
	 }];
	NSLog(@"%s", __PRETTY_FUNCTION__);
}


- (void) viewDidUnload
{
	[self setTextView:nil];
	[self setProgressView:nil];
	[self setDoneButton:nil];
    [super viewDidUnload];
}


- (void) viewWillDisappear:(BOOL)animated
{
	// save text
	self.document.contents = self.textView.text;
	[self.document closeWithCompletionHandler:^(BOOL success) 
	{
		NSLog(@"%s CLOSED", __PRETTY_FUNCTION__);
	}];
	NSLog(@"%s", __PRETTY_FUNCTION__);
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Editing in the text view
// ---------------------------------------------------------------------------------------------------------------

- (void) textViewDidBeginEditing:(UITextView *)textView
{
	// show the done button
	self.navigationItem.rightBarButtonItem = self.doneButton;
}


- (IBAction) doneButtonPressed:(id)sender 
{
	// stop the text editing
	[self.textView endEditing:YES];
	[self.document updateChangeCount:UIDocumentChangeDone];
	
	// hide the done button
	self.navigationItem.rightBarButtonItem = nil;
}


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Actions
// ---------------------------------------------------------------------------------------------------------------

- (IBAction) shareButtonPressed:(id)sender 
{
	// save text
	self.document.contents = self.textView.text;
	[self.document saveToURL:self.document.fileURL 
	   forSaveOperation:UIDocumentSaveForOverwriting 
	  completionHandler:^(BOOL success) 
	 {
		 // let's make it with twitter...
		 if (![TWTweetComposeViewController canSendTweet])
		 {
			 [[[UIAlertView alloc] initWithTitle:@"Cannot share file"
										 message:@"It seems that twitter in not configured."
										delegate:nil
							   cancelButtonTitle:@"Ok"
							   otherButtonTitles:nil] show];
		 }
		 else
		 {
			 // display progess indicator
			 self.progressText.text = @"Preparing sharing…";
			 [self.view addSubview:self.progressView];
			 NSLog(@"%s %@, %@", __PRETTY_FUNCTION__, self.progressText, self.progressView);

			 
			 // get url to share to
			 NSURL *shareURL;
			 //		 NSError *outError = nil;
			 shareURL = [[NSFileManager defaultManager] URLForPublishingUbiquitousItemAtURL:document.fileURL 
																			 expirationDate:nil 
																					  error:nil];
			 // remove progress indicator
			 [self.progressView removeFromSuperview];
			 
			 // Show the tweet ui
			 TWTweetComposeViewController* tweetController = [[TWTweetComposeViewController alloc] init];
			 [tweetController setInitialText:@"This file from #iCloudPlayground is shared online. Fantastisch!"];
			 [tweetController addURL:shareURL];
			 
			 [self presentModalViewController:tweetController animated:YES];
		 }
	 }];
}


- (IBAction) openExternally:(id)sender
{
	self.document.contents = self.textView.text;
	[self.document saveToURL:self.document.fileURL 
	   forSaveOperation:UIDocumentSaveForOverwriting 
	  completionHandler:^(BOOL success) 
	 {
//		 // copy file to local cache
//		 NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
//																				 NSUserDomainMask, YES) objectAtIndex:0];
//		 NSURL *cacheURL = [[NSURL fileURLWithPath:documentsDirectoryPath] URLByAppendingPathComponent:self.document.localizedName];
//		 
//		 NSError *outError = nil;
//		 if (![[NSFileManager defaultManager] copyItemAtURL:self.document.fileURL 
//													  toURL:cacheURL 
//													  error:&outError])
//		 {
//			 NSLog(@"%s %@", __PRETTY_FUNCTION__, outError);
//			 return;
//		 }

		 
		 // bring up dialog from doc interaction controller
//		 UIDocumentInteractionController* docController = [UIDocumentInteractionController interactionControllerWithURL:cacheURL];
		 UIDocumentInteractionController* docController = [UIDocumentInteractionController interactionControllerWithURL:self.document.fileURL];
		 docController.delegate = self;
		 
		 BOOL didOpen = [docController presentOpenInMenuFromRect:CGRectZero
														  inView:self.view.window.rootViewController.view
														animated:YES];
		 if (!didOpen)
		 {
			 NSString *title = [NSString stringWithFormat:@"Cannot open file in other apps"];
			 NSString *alertMessage = [NSString stringWithFormat:@"Unfortunately, there is no app installed that can handle this kind of file."];
			 NSString *ok = [NSString stringWithFormat:@"Ok"];
			 
			 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
															 message:alertMessage
															delegate:nil 
												   cancelButtonTitle:ok
												   otherButtonTitles:nil];
			[alert show];
		 }
		 
//		 [[NSFileManager defaultManager] removeItemAtURL:cacheURL error:nil];
	 }];
}


- (void) documentInteractionController: (UIDocumentInteractionController *) controller willBeginSendingToApplication: (NSString *) application
{
	NSLog(@"%s %@", __PRETTY_FUNCTION__, application);
}


- (void) documentInteractionControllerDidDismissOpenInMenu: (UIDocumentInteractionController *) controller
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
}


- (void) documentInteractionController: (UIDocumentInteractionController *) controller didEndSendingToApplication: (NSString *) application
{
	NSLog(@"%s %@", __PRETTY_FUNCTION__, application);
}


@end


