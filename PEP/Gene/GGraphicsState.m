//
//  GGraphicsState.m
//  PEP
//
//  Created by Aaron Elkins on 9/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GGraphicsState.h"
#import "GColorSpace.h"
#import "GPage.h"

@implementation GGraphicsState
+ (id)create {
    GGraphicsState *gs = [[GGraphicsState alloc] init];
    [gs initState];
    return gs;
}

- (void)initState {
    [self setCTM:CGAffineTransformIdentity];
    
    // Init DeviceGray color space
    GColorSpace *cs = [GColorSpace colorSpaceWithName:@"DeviceGray" page:nil];
    [self setColorSpace:cs];
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
