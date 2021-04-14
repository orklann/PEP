//
//  GColorSpace.h
//  PEP
//
//  Created by Aaron Elkins on 4/14/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDeviceGray @"DeviceGray"

NS_ASSUME_NONNULL_BEGIN

@class GPage;

@interface GColorSpace : NSObject {
    GPage *page;
}

+ (id)colorSpaceWithName:(NSString*)colorSpaceName page:(GPage*)page;

@end

NS_ASSUME_NONNULL_END
