//
//  GColorSpace.m
//  PEP
//
//  Created by Aaron Elkins on 4/14/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GColorSpace.h"
#import "GDeviceGrayColorSpace.h"
#import "GDeviceRGBColorSpace.h"

@implementation GColorSpace

+ (id)colorSpaceWithName:(NSString*)colorSpaceName page:(nullable GPage*)page {
    id cs;
    if ([colorSpaceName isEqualToString:kDeviceGray]) {
        cs = [GDeviceGrayColorSpace colorSpaceWithName:colorSpaceName page:page];
    } else if ([colorSpaceName isEqualToString:kDeviceRGB]) {
        cs = [GDeviceRGBColorSpace colorSpaceWithName:colorSpaceName page:page];
    }
    return cs;
}

/* This method does not matter, because we never call it, just to make compiler happy. */
- (NSColor*)mapColor:(GCommandObject*)cmd {
    return [NSColor blackColor];
}
@end
