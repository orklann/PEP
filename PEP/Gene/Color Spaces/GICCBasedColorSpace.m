//
//  GICCBasedColorSpace.m
//  PEP
//
//  Created by Aaron Elkins on 4/27/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GICCBasedColorSpace.h"
#import "GDeviceGrayColorSpace.h"
#import "GDeviceRGBColorSpace.h"
#import "GObjects.h"

@implementation GICCBasedColorSpace
+ (id)colorSpace:(GStreamObject*)stream page:(nullable GPage *)page {
    id cs;
    GNumberObject *N = [[[stream dictionaryObject] value] objectForKey:@"N"];
    int n = [N intValue];
    GObject *alternate = [[[stream dictionaryObject] value] objectForKey:@"Alternate"];
    if ([alternate type] == kNameObject) {
        NSString *colorSpaceName = [(GNameObject*)alternate value];
        cs = [GColorSpace colorSpaceWithName:colorSpaceName page:page];
    } else if ([alternate type] == kArrayObject) {
        // TODO: Handle this case while alternate is an array
        NSLog(@"TODO: Need to handle alternate is an array for ICCBasedColorSpace");
    } else if (alternate == nil) {
        if (n == 1) {
            cs = [GDeviceGrayColorSpace colorSpaceWithName:kDeviceGray page:page];
        } else if (n == 3) {
            cs = [GDeviceRGBColorSpace colorSpaceWithName:kDeviceRGB page:page];
        } else if (n == 4) {
            // TODO: Need to handle n == 4
            NSLog(@"TODO: Need to handle n = 4 for ICCBasedColorSpace");
        }
    }
    return cs;
}

- (NSColor*)mapColor:(GCommandObject*)cmd {
    return [NSColor blackColor];
}
@end
