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
    [gs initState];
    return gs;
}

- (void)initState {
    [self setCTM:CGAffineTransformIdentity];
    [self setStrokeColor:[NSColor blackColor]];
    [self setNonStrokeColor:[NSColor blackColor]];
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
    [newGraphicsState setColorSpace:_colorSpace];
    [newGraphicsState setStrokeColor:_strokeColor];
    [newGraphicsState setNonStrokeColor:_nonStrokeColor];
    return newGraphicsState;
}
@end
