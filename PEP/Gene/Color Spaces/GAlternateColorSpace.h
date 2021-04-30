//
//  GAlternateColorSpace.h
//  PEP
//
//  Created by Aaron Elkins on 4/30/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GColorSpace.h"
#import "GFunction.h"

NS_ASSUME_NONNULL_BEGIN

@interface GAlternateColorSpace : GColorSpace {
    
}

@property (readwrite) GColorSpace *baseColorSpace;
@property (readwrite) GFunction *function;

+ (id)colorSpace:(GColorSpace*)base function:(GFunction*)fn;
- (NSColor*)mapColor:(GCommandObject*)cmd;
@end

NS_ASSUME_NONNULL_END
