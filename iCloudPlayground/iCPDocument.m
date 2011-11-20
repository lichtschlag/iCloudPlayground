//
//  iCPDocument.m
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag on 16/Nov/11.
//  Copyright (c) 2011 Leonhard Lichtschlag. All rights reserved.
//

#import "iCPDocument.h"

NSString *const iCPPathExtension = @"txt";

// ===============================================================================================================
@implementation iCPDocument
// ===============================================================================================================

- (id) contentsForType:(NSString *)typeName error:(NSError **)outError
{
	NSLog(@"%s SAVING", __PRETTY_FUNCTION__);
	NSString* contents = @"I am simply a text.";
    return [contents dataUsingEncoding: NSUnicodeStringEncoding];
}


- (void) handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
    NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
}


- (NSString *) localizedName
{
	return [self.fileURL lastPathComponent];
}


- (BOOL) loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError
{
	return YES;
}


@end
