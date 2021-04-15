//
//  GColorSpace.h
//  PEP
//
//  Created by Aaron Elkins on 4/14/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#define kDeviceGray @"DeviceGray"

NS_ASSUME_NONNULL_BEGIN

@class GPage;
@class GCommandObject;

@interface GColorSpace : NSObject {
    GPage *page;
}

+ (id)colorSpaceWithName:(NSString*)colorSpaceName page:(GPage*)page;

/* No implementation, becuase we never call it, as a virtual function as like in C++ */
- (NSColor*)mapColor:(GCommandObject*)cmd;
@end

NS_ASSUME_NONNULL_END
