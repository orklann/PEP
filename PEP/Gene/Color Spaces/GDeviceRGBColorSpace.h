//
//  GDeviceRGBColorSpace.h
//  PEP
//
//  Created by Aaron Elkins on 4/19/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GColorSpace.h"

NS_ASSUME_NONNULL_BEGIN
@class GCommandObject;

@interface GDeviceRGBColorSpace : GColorSpace {
    
}

+ (id)colorSpaceWithName:(NSString *)colorSpaceName page:(nullable GPage *)page;
- (NSColor*)mapColor:(GCommandObject*)cmd;
@end

NS_ASSUME_NONNULL_END
