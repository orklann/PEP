//
//  GDeviceGrayColorSpace.m
//  PEP
//
//  Created by Aaron Elkins on 4/14/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GDeviceGrayColorSpace.h"

GDeviceGrayColorSpace *_deviceGrayColorSpace = nil;

@implementation GDeviceGrayColorSpace

+ (id)colorSpaceWithName:(NSString *)colorSpaceName page:(GPage *)page {
    // Make GDeviceGrayColorSpace always singleton to save memory
    if (_deviceGrayColorSpace == nil) {
        _deviceGrayColorSpace = [[GDeviceGrayColorSpace alloc] init];
    }
    return _deviceGrayColorSpace;
}
@end
