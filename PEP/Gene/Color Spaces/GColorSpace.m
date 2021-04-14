//
//  GColorSpace.m
//  PEP
//
//  Created by Aaron Elkins on 4/14/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GColorSpace.h"
#import "GDeviceGrayColorSpace.h"

@implementation GColorSpace

+ (id)colorSpaceWithName:(NSString*)colorSpaceName page:(GPage*)page {
    id cs;
    if ([colorSpaceName isEqualToString:kDeviceGray]) {
        cs = [GDeviceGrayColorSpace colorSpaceWithName:colorSpaceName page:page];
    }
    return cs;
}
@end
