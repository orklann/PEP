//
//  GSeparationColorSpace.h
//  PEP
//
//  Created by Aaron Elkins on 5/1/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GColorSpace.h"

NS_ASSUME_NONNULL_BEGIN

@interface GSeparationColorSpace : GColorSpace

+ (id)colorSpaceWithArray:(GArrayObject*)arrayObject page:(nullable GPage*)page;
- (NSColor*)mapColor:(GCommandObject*)cmd;
@end

NS_ASSUME_NONNULL_END
