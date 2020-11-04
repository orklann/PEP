//
//  GGraphicsState.m
//  PEP
//
//  Created by Aaron Elkins on 9/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GGraphicsState.h"

@implementation GGraphicsState
+ (id)create {
    GGraphicsState *gs = [[GGraphicsState alloc] init];
    [gs setCTM:CGAffineTransformIdentity];
    return gs;
}

- (void)setCTM:(CGAffineTransform)tf {
    ctm = tf;
}

- (CGAffineTransform)ctm {
    return ctm;
}

- (GGraphicsState*)clone {
    GGraphicsState *newGraphicsState = [GGraphicsState create];
    [newGraphicsState setCTM:ctm];
    return newGraphicsState;
}
@end
