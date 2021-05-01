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
#define kDeviceRGB @"DeviceRGB"
#define kICCBased @"ICCBased"

NS_ASSUME_NONNULL_BEGIN

@class GPage;
@class GCommandObject;
@class GArrayObject;

@interface GColorSpace : NSObject {
    GPage *page;
}

+ (id)colorSpaceWithName:(NSString*)colorSpaceName page:(nullable GPage*)page;
+ (id)colorSpaceWithArray:(GArrayObject*)arrayObject page:(nullable GPage*)page;

/*
 * We never call it, it works as a virtual function as like in C++.
 * This method is just to make Xcode compiler happy.
 */
- (NSColor*)mapColor:(GCommandObject*)cmd;
@end

NS_ASSUME_NONNULL_END
