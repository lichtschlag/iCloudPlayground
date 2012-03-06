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

- (IBAction) chooseCurrentVersion:(id) sender
{
	// remove the alternate version (but only the one we presented to the user)
	[self.alternateVersion removeAndReturnError:nil];
	
	// and mark version as resolved
	// It seems that this step is unneccessary, because resoled is already YES, but the apple doc suggests it.
	NSArray* conflictVersions = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:self.currentDocument.fileURL];
	if ([conflictVersions containsObject:self.alternateVersion])
		self.alternateVersion.resolved = YES;
	
	// release pointers
	self.currentDocument		= nil;
	self.alternateVersion		= nil;
	
	// end merge
	[self.navigationController popViewControllerAnimated:YES];
}


- (IBAction) chooseAlternateVersion:(id) sender
{		
	// NOTE: the code below discards ALL other versions, not just the current one.
	// calls to [currentVersion removeAndReturnError:&outError]; always failed, so did not figure out how to delete
	// just this one version. The code below is from Apple's documentation.

	[self.alternateVersion replaceItemAtURL:self.currentDocument.fileURL options:0 error:nil];
	[NSFileVersion removeOtherVersionsOfItemAtURL:self.currentDocument.fileURL error:nil];
	[self.currentDocument revertToContentsOfURL:self.currentDocument.fileURL completionHandler:^(BOOL success) 
	{
		// wait for the reload to finish, because we want to update the text field as soon as we return
		
		NSArray* conflictVersions = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:self.currentDocument.fileURL];
		for (NSFileVersion* fileVersion in conflictVersions) 
		{
			fileVersion.resolved = YES;
		}
		
		// release pointers
		self.currentDocument		= nil;
		self.alternateVersion		= nil;
		
		// end merge dialog
		[self.navigationController popViewControllerAnimated:YES];
	}];
}


@end

