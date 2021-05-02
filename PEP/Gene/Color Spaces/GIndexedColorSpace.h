//
//  GIndexedColorSpace.h
//  PEP
//
//  Created by Aaron Elkins on 5/2/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GColorSpace.h"

NS_ASSUME_NONNULL_BEGIN

@interface GIndexedColorSpace : GColorSpace {
    
}

@property (readwrite) GColorSpace *baseColorSpace;
@property (readwrite) int hival;
@property (readwrite) NSData *lookupTable;

+ (id)colorSpaceWithArray:(GArrayObject*)arrayObject page:(nullable GPage*)page;
- (NSColor*)mapColor:(GCommandObject*)cmd;
@end

NS_ASSUME_NONNULL_END
