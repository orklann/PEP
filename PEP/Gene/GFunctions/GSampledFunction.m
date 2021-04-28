//
//  GSampledFunction.m
//  PEP
//
//  Created by Aaron Elkins on 4/28/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GSampledFunction.h"
#import "GObjects.h"

@implementation GSampledFunction

+ (id)functionWithStreamObject:(GStreamObject*)streamObj {
    GSampledFunction *obj = [[GSampledFunction alloc] init];
    [obj setStreamObject:streamObj];
    return obj;
}

- (void)setStreamObject:(GStreamObject*)so {
    streamObj = so;
}
@end
