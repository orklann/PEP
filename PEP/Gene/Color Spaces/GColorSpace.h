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
#define kDeviceCMYK @"DeviceCMYK"
#define kICCBased @"ICCBased"
#define kSeparation @"Separation"
#define kIndexed @"Indexed"

NS_ASSUME_NONNULL_BEGIN

@class GPage;
@class GCommandObject;
@class GArrayObject;

@interface GColorSpace : NSObject {
    GPage *page;
}

/*
 * Number of components in color space
 * For example, for DeviceGray, numComps is 1.
 * For DeviceRGB, numComps is 3, etc
 */
@property (readwrite) int numComps;

+ (id)colorSpaceWithName:(NSString*)colorSpaceName page:(nullable GPage*)page;
+ (id)colorSpaceWithArray:(GArrayObject*)arrayObject page:(nullable GPage*)page;

/*
 * We never call it, it works as a virtual function as like in C++.
 * This method is just to make Xcode compiler happy.
 */
- (NSColor*)mapColor:(GCommandObject*)cmd;
@end

NS_ASSUME_NONNULL_END
