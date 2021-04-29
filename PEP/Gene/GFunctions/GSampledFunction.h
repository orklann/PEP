//
//  GSampledFunction.h
//  PEP
//
//  Created by Aaron Elkins on 4/28/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GFunction.h"

NS_ASSUME_NONNULL_BEGIN
@class GStreamObject;

/* Type0 function a.k.a sampled function */
@interface GSampledFunction : GFunction {
    GStreamObject *streamObj;
}

@property (readwrite) int inputSize;
@property (readwrite) NSArray *domain;
@property (readwrite) int outputSize;
@property (readwrite) NSArray *range;
@property (readwrite) NSArray *size;
@property (readwrite) int bps;
@property (readwrite) NSArray *encode;
@property (readwrite) NSArray *decode;
@property (readwrite) NSArray *samples;

+ (id)functionWithStreamObject:(GStreamObject*)streamObj;
- (void)setStreamObject:(GStreamObject*)so;
- (NSArray*)eval:(NSArray*)inputs;
@end

NS_ASSUME_NONNULL_END
