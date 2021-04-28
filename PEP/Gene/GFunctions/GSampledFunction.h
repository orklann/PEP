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
@interface GSampledFunction : GFunction {
    GStreamObject *streamObj;
}

+ (id)functionWithStreamObject:(GStreamObject*)streamObj;
- (void)setStreamObject:(GStreamObject*)so;
@end

NS_ASSUME_NONNULL_END
