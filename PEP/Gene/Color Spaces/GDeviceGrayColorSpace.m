//
//  GDeviceGrayColorSpace.m
//  PEP
//
//  Created by Aaron Elkins on 4/14/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GDeviceGrayColorSpace.h"

@implementation GDeviceGrayColorSpace

+ (id)colorSpaceWithName:(NSString *)colorSpaceName page:(GPage *)page {
    GDeviceGrayColorSpace *cs = [[GDeviceGrayColorSpace alloc] init];
    return cs;
}
@end
