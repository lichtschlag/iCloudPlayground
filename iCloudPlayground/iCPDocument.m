//
//  iCPDocument.m
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag (leonhard@lichtschlag.net) on 16/Nov/11.
//  Copyright (c) 2011 Leonhard Lichtschlag. All rights reserved.
//

#import "iCPDocument.h"

NSString *const iCPPathExtension = @"txt";

// ===============================================================================================================
@implementation iCPDocument
// ===============================================================================================================

@synthesize contents;


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Document Life Cycle
// ---------------------------------------------------------------------------------------------------------------

- (id) initWithFileURL:(NSURL *)url
{
	self = [super initWithFileURL:url];
	if (self) 
	{
		self.contents = @"I am simply a text.";
	}
	return self;
}


- (NSString *) localizedName
{
	return [self.fileURL lastPathComponent];
}


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Loading and Saving
// ---------------------------------------------------------------------------------------------------------------

- (id) contentsForType:(NSString *)typeName error:(NSError **)outError
{
	NSData *data = [self.contents dataUsingEncoding: NSUTF8StringEncoding];
	return data;
}


- (BOOL) loadFromContents:(id)fileContents ofType:(NSString *)typeName error:(NSError **)outError
{
	self.contents = [[NSString alloc] initWithData:fileContents encoding:NSUTF8StringEncoding];  
	return YES;
}


- (void) handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
	NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
}


@end

