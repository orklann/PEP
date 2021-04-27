//
//  GICCBasedColorSpace.h
//  PEP
//
//  Created by Aaron Elkins on 4/27/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GColorSpace.h"

NS_ASSUME_NONNULL_BEGIN
@class GCommandObject;
@class GStreamObject;

@interface GICCBasedColorSpace : GColorSpace {
    
}
+ (id)colorSpace:(GStreamObject*)stream page:(nullable GPage *)page;
- (NSColor*)mapColor:(GCommandObject*)cmd;
@end

NS_ASSUME_NONNULL_END
