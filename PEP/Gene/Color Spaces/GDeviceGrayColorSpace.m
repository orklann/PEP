//
//  GDeviceGrayColorSpace.m
//  PEP
//
//  Created by Aaron Elkins on 4/14/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GDeviceGrayColorSpace.h"
#import "GObjects.h"

GDeviceGrayColorSpace *_deviceGrayColorSpace = nil;

@implementation GDeviceGrayColorSpace

+ (id)colorSpaceWithName:(NSString *)colorSpaceName page:(GPage *)page {
    // Make GDeviceGrayColorSpace always singleton to save memory
    if (_deviceGrayColorSpace == nil) {
        _deviceGrayColorSpace = [[GDeviceGrayColorSpace alloc] init];
    }
    return _deviceGrayColorSpace;
}

- (NSColor*)mapColor:(GCommandObject*)cmd {
    NSArray *args = [cmd args];
    GNumberObject *grayScaleObject = [args lastObject];
    CGFloat grayScale = [grayScaleObject getRealValue];
    return [NSColor colorWithWhite:grayScale alpha:1.0];
}
@end
