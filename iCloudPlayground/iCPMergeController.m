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
@property (retain) NSFileVersion *alternateVersion;

@end


// ===============================================================================================================
@implementation iCPMergeController
// ===============================================================================================================

@synthesize currentDocument;
@synthesize alternateDocument;
@synthesize currentContents;
@synthesize alternateContents;
@synthesize currentVersionInfo;
@synthesize alternateVersionInfo;
@synthesize alternateVersion;


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark View Life Cycle
// ---------------------------------------------------------------------------------------------------------------

- (void) viewDidLoad
{
	[super viewDidLoad];

	// visual style of the text layers
	UIColor *gray = [UIColor colorWithWhite:0.607 alpha:1.000];

	[self.alternateContents.layer setCornerRadius:8.0];
	[self.alternateContents.layer setBorderColor:[gray CGColor]];
	[self.alternateContents.layer setBorderWidth:1.0];

	[self.currentContents.layer setCornerRadius:8.0];
	[self.currentContents.layer setBorderColor:[gray CGColor]];
	[self.currentContents.layer setBorderWidth:1.0];

	// we assume that the document is still open
	NSAssert(currentDocument.documentState & UIDocumentStateInConflict, @"Document was closed or not in conflict");
	self.currentContents.text = self.currentDocument.contents;
	
	// get the contents of the alternative version, note that there could be more than one alternate version
	self.alternateVersion = [[NSFileVersion otherVersionsOfItemAtURL:currentDocument.fileURL] lastObject];
	NSAssert(self.alternateVersion, @"No conflicting version found");
	
	self.alternateDocument = [[iCPDocument alloc] initWithFileURL:self.alternateVersion.URL];
	[self.alternateDocument openWithCompletionHandler:^(BOOL success)
	 {
		 if (success)
		 {
			 self.alternateContents.text = self.alternateDocument.contents;
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
	
	// Tell the user some of the stats of the versions
	NSFileVersion *currentVersion		= [NSFileVersion currentVersionOfItemAtURL:self.currentDocument.fileURL];
	NSDate *versionDate				= [currentVersion modificationDate];
	NSDateFormatter *dateFormatter		= [[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	NSString *dateString				= [dateFormatter stringFromDate:versionDate];
	NSString *versionSaver				= [currentVersion localizedNameOfSavingComputer];	
	
	self.currentVersionInfo.text = [NSString stringWithFormat:@"%@ \n%@", dateString, versionSaver];
	
	versionDate		= [self.alternateVersion modificationDate];
	dateString		= [dateFormatter stringFromDate:versionDate];
	versionSaver	= [currentVersion localizedNameOfSavingComputer];
	
	self.alternateVersionInfo.text = [NSString stringWithFormat:@"%@ \n%@", dateString, versionSaver];
}


- (void) viewDidUnload
{
	// UI
	[self setCurrentContents:nil];
	[self setAlternateContents:nil];
	[self setCurrentVersionInfo:nil];
	[self setAlternateVersionInfo:nil];

	// Version Handling
	[self setCurrentDocument:nil];
	[self setAlternateDocument:nil];
	[self setAlternateVersion:nil];
	
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

- (IBAction) chooseAlternateVersion:(id) sender
{
	NSFileVersion *currentVersion		= [NSFileVersion currentVersionOfItemAtURL:self.currentDocument.fileURL];
	
	// overwrite the current version and let our document reload
	[self.alternateVersion replaceItemAtURL:self.currentDocument.fileURL options:0 error:nil];
	[self.currentDocument revertToContentsOfURL:self.currentDocument.fileURL completionHandler:nil];
	
	// remove the current version
	BOOL didDelete = [currentVersion removeAndReturnError:nil];
	// TODO: this assertion fires...., do log errer
	NSAssert(didDelete, @"Could not remove Version");

	// and mark the (now discarded) current version as resolved
	// TODO: logs a "tried and failed error", break here and check resolved status of both versions.
	NSLog(@"%s \"current\" is resolved:%d, \"alternate\" is resolved:%d", __PRETTY_FUNCTION__, 
		  currentVersion.isResolved, alternateVersion.isResolved);

	currentVersion.resolved = YES;
	//	self.alternateVersion.resolved = YES;

	// release pointers
	self.currentDocument		= nil;
	self.currentVersionInfo	= nil;

	// end merge dialog
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction) chooseCurrentVersion:(id) sender
{
	// remove the alternate version (but only the one we presented to the user)
	[self.alternateVersion removeAndReturnError:nil];
	
	// and mark version as resolved
	// TODO: logs a "tried and failed error"
	self.alternateVersion.resolved = YES;
	
	// release pointers
	self.currentDocument		= nil;
	self.currentVersionInfo	= nil;
	
	// end merge
	[self dismissViewControllerAnimated:YES completion:nil];
}


@end

