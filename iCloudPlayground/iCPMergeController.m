//
//  iCPMergeController.m
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag on 5/Mar/12.
//  Copyright (c) 2012 Media Computing Group, RWTH Aachen University. All rights reserved.
//

#import "iCPMergeController.h"
#import "iCPDocument.h"
#include <QuartzCore/CALayer.h>


// ===============================================================================================================
@interface iCPMergeController ()
// ===============================================================================================================

@property (retain) iCPDocument *alternateDocument;

@end


// ===============================================================================================================
@implementation iCPMergeController
// ===============================================================================================================

@synthesize document;
@synthesize alternateDocument;
@synthesize textField;
@synthesize alternateTextField;


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark View Life Cycle
// ---------------------------------------------------------------------------------------------------------------

- (void) viewDidLoad
{
    [super viewDidLoad];

	// visual style of the text layers
	UIColor *gray = [UIColor colorWithWhite:0.607 alpha:1.000];

	[self.alternateTextField.layer setCornerRadius:10.0];
	[self.alternateTextField.layer setBorderColor:[gray CGColor]];
	[self.alternateTextField.layer setBorderWidth:1.0];

	[self.textField.layer setCornerRadius:10.0];
	[self.textField.layer setBorderColor:[gray CGColor]];
	[self.textField.layer setBorderWidth:1.0];

	// we assume that the document is still open
	NSAssert(document.documentState & UIDocumentStateInConflict, @"Document was closed or not in conflict");
	self.textField.text = self.document.contents;
	
	// get the contents of the alternative version
	NSFileVersion *otherVersion = [[NSFileVersion otherVersionsOfItemAtURL:document.fileURL] lastObject];
	NSAssert(otherVersion, @"No conflicting version found");
	
	self.alternateDocument = [[iCPDocument alloc] initWithFileURL:otherVersion.URL];
	[self.alternateDocument openWithCompletionHandler:^(BOOL success)
	 {
		 if (success)
		 {
			 self.alternateTextField.text = self.alternateDocument.contents;
			 [self.alternateDocument closeWithCompletionHandler:^(BOOL success) 
			  {
				  if (!success)
					  NSAssert(NO , @"There was a problem closing the alternate document version");
			  }];
			 [self setAlternateDocument:nil];
		 }
		 else
		 {
			 NSAssert(NO , @"Could not open alternate document version");
		 }
	 }];
}


- (void) viewDidUnload
{
	[self setTextField:nil];
	[self setAlternateTextField:nil];
	[self setDocument:nil];
	[self setAlternateDocument:nil];
	
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

