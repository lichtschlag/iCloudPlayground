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
@interface iCPDocumentViewController ()
// ===============================================================================================================

- (void) showProgressScreenWithLabel:(NSString *)label;
- (void) hideProgressScreen;

@end


// ===============================================================================================================
@implementation iCPDocumentViewController
// ===============================================================================================================

@synthesize document;
@synthesize textView;
@synthesize progressView;
@synthesize doneButton;
@synthesize openButton;
@synthesize progressText;
@synthesize docController;
@synthesize statusText;


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark View lifecycle
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
	
	[self showProgressScreenWithLabel:@"Loading document…"];
	
	// hide the done button before the user starts editing
	self.navigationItem.rightBarButtonItem = nil;

	// get contents from document
	[self.document openWithCompletionHandler:^(BOOL success)
	 {
		 if (success)
		 {
			 self.textView.text = document.contents;
			 [self hideProgressScreen];
		 }
		 else
		 {
			 [[[UIAlertView alloc] initWithTitle:@"Cannot open document"
										 message:@"Something went wrong. It's not your fault."
										delegate:nil
							   cancelButtonTitle:@"Ok"
							   otherButtonTitles:nil] show];
		 }
	 }];
	
	// register for state changes
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(documentStateChanged:)
                                                 name:UIDocumentStateChangedNotification
											   object:nil];
}


- (void) viewDidUnload
{
	[self setTextView:nil];
	[self setProgressView:nil];
	[self setProgressText:nil];
	[self setDoneButton:nil];
	[self setOpenButton:nil];
	[self setDocController:nil];
	[self setStatusText:nil];
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super viewDidUnload];
}


- (void) viewWillDisappear:(BOOL)animated
{
	// figure out if changes were made
	if (![self.textView.text isEqualToString:self.document.contents])
	{
		// save text
		self.document.contents = self.textView.text;
		[self.document updateChangeCount:UIDocumentChangeDone];
	}
	
	[self.document closeWithCompletionHandler:^(BOOL success) 
	{
		NSLog(@"%s CLOSED", __PRETTY_FUNCTION__);
	}];
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
	// display progess indicator
	[self showProgressScreenWithLabel:@"Preparing sharing…"];
	
	// save text
	self.document.contents = self.textView.text;
	[self.document saveToURL:self.document.fileURL 
	   forSaveOperation:UIDocumentSaveForOverwriting 
	  completionHandler:^(BOOL success) 
	 {
		 // let's make it with twitter...
		 if (![TWTweetComposeViewController canSendTweet])
		 {
			 // remove progress indicator
			 [self hideProgressScreen];

			 // ups
			 [[[UIAlertView alloc] initWithTitle:@"Cannot share file"
										 message:@"It seems that twitter in not configured."
										delegate:nil
							   cancelButtonTitle:@"Ok"
							   otherButtonTitles:nil] show];
		 }
		 else
		 {
			 // get url to share to
			 NSURL *shareURL;
			 //		 NSError *outError = nil;
			 shareURL = [[NSFileManager defaultManager] URLForPublishingUbiquitousItemAtURL:document.fileURL 
																			 expirationDate:nil 
																					  error:nil];
			 // remove progress indicator
			 [self hideProgressScreen];
			 
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
		 // bring up dialog from doc interaction controller
		 self.docController = [UIDocumentInteractionController interactionControllerWithURL:self.document.fileURL];
		 
		 BOOL didOpen = [docController presentOpenInMenuFromRect:CGRectZero
														  inView:self.openButton
														animated:YES];
		 if (!didOpen)
		 {
			 [[[UIAlertView alloc] initWithTitle:@"Cannot open file in other apps"
										 message:@"Unfortunately, there is no app installed that can handle this kind of file."
										delegate:nil 
							   cancelButtonTitle:@"Ok"
							   otherButtonTitles:nil] show];
		 }
	 }];
}


- (void) documentStateChanged:(NSNotification *)notification;
{
	UIDocumentState docState = [document documentState];
	NSMutableArray *docStateTextComponents = [NSMutableArray array];
	
	if (docState == UIDocumentStateNormal)	// all bits 0
		[docStateTextComponents addObject:@"Open"];
	if (docState & UIDocumentStateClosed)	// the following have one bit = 1
		[docStateTextComponents addObject:@"Closed"];
	if (docState & UIDocumentStateInConflict)
		[docStateTextComponents addObject:@"Merge Conflict"];
	if (docState & UIDocumentStateSavingError)
		[docStateTextComponents addObject:@"Saving Error"];
	if (docState & UIDocumentStateEditingDisabled)
		[docStateTextComponents addObject:@"NoEdit"];
	
	self.statusText.text = [NSString stringWithFormat:@"Document state: %@",
							[docStateTextComponents componentsJoinedByString:@", "]];
}



// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Progress helpers
// ---------------------------------------------------------------------------------------------------------------

- (void) showProgressScreenWithLabel:(NSString *)label
{
	// visual style of the loading layer
	[self.progressView.layer setCornerRadius:10.0];

	// display progess indicator
	self.progressText.text = label;
	[self.view addSubview:self.progressView];
}


- (void) hideProgressScreen
{
	// remove progress indicator
	[self.progressView removeFromSuperview];
}


@end


