//
//  iCPDocument.m
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag on 16/Nov/11.
//  Copyright (c) 2011 Leonhard Lichtschlag. All rights reserved.
//

#import "iCPDocument.h"

NSString *const iCPPathExtension = @"iCloudPlayground";

// ===============================================================================================================
@implementation iCPDocument
// ===============================================================================================================

- (id) contentsForType:(NSString *)typeName error:(NSError **)outError
{
    NSLog(@"%s %@", __PRETTY_FUNCTION__, typeName);

    NSString* contents = @"I am simply a text.";
    return [contents dataUsingEncoding: NSUnicodeStringEncoding];
}


- (void) handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
    NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
}

@end
