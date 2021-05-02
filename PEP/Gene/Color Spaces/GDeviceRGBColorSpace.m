//
//  GDeviceRGBColorSpace.m
//  PEP
//
//  Created by Aaron Elkins on 4/19/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GDeviceRGBColorSpace.h"
#import "GObjects.h"

GDeviceRGBColorSpace *_deviceRGBColorSpace = nil;

@implementation GDeviceRGBColorSpace

+ (id)colorSpaceWithName:(NSString *)colorSpaceName page:(nullable GPage *)page {
    // Make GDeviceRGBColorSpace always singleton to save memory
    if (_deviceRGBColorSpace == nil) {
        _deviceRGBColorSpace = [[GDeviceRGBColorSpace alloc] init];
        [_deviceRGBColorSpace setNumComps:3];
    }
    return _deviceRGBColorSpace;
}

- (NSColor*)mapColor:(GCommandObject*)cmd {
    NSArray *args = [cmd args];
    CGFloat red = [[args objectAtIndex:0] getRealValue];
    CGFloat green = [[args objectAtIndex:1] getRealValue];
    CGFloat blue = [[args objectAtIndex:2] getRealValue];
    return [NSColor colorWithRed:red green:green blue:blue alpha:1.0];
}
@end
