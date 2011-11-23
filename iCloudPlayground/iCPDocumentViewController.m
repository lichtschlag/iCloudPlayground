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

// ===============================================================================================================
@implementation iCPDocumentViewController
// ===============================================================================================================

@synthesize document;
@synthesize textView;
@synthesize loadingView;
@synthesize doneButton;


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
	[self.loadingView.layer setCornerRadius:10.0];
	
	// hide the done button before the user starts editing
	self.navigationItem.rightBarButtonItem = nil;

	// get contents from document
	[document openWithCompletionHandler:^(BOOL success)
	 {
		 if (success)
		 {
			 self.textView.text = document.contents;
			 [self.loadingView removeFromSuperview];
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
	[self setLoadingView:nil];
	[self setDoneButton:nil];
    [super viewDidUnload];
}


- (void) viewWillDisappear:(BOOL)animated
{
	// save text
	document.contents = self.textView.text;
	[document closeWithCompletionHandler:^(BOOL success) 
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
	document.contents = self.textView.text;
	[document saveToURL:document.fileURL 
	   forSaveOperation:UIDocumentSaveForOverwriting 
	  completionHandler:^(BOOL success) 
	 {
		 // get url to share to
		 NSURL *shareURL;
		 //		 NSError *outError = nil;
		 shareURL = [[NSFileManager defaultManager] URLForPublishingUbiquitousItemAtURL:document.fileURL 
																		 expirationDate:nil 
																				  error:nil];
		 NSLog(@"%s icloud URL: %@", __PRETTY_FUNCTION__, shareURL);
	 }];
}


- (IBAction) openExternally:(id)sender
{
	BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:self.document.fileURL];
	BOOL didOpen = [[UIApplication sharedApplication] openURL:self.document.fileURL];
	NSLog(@"%s %d %d", __PRETTY_FUNCTION__, canOpen, didOpen);
}


@end


