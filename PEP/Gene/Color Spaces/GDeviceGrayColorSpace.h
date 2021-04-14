//
//  GDeviceGrayColorSpace.h
//  PEP
//
//  Created by Aaron Elkins on 4/14/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GColorSpace.h"

NS_ASSUME_NONNULL_BEGIN

@interface GDeviceGrayColorSpace : GColorSpace {
    
}

+ (id)colorSpaceWithName:(NSString *)colorSpaceName page:(GPage *)page;
@end

NS_ASSUME_NONNULL_END
