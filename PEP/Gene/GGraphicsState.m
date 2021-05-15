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
    [self setStrokeColorSpace:cs];
    [self setNonStrokeColorSpace:cs];
    [self setStrokeColor:[NSColor blackColor]];
    [self setNonStrokeColor:[NSColor blackColor]];
    [self setOverprintStroking:NO];
    [self setOverprintNonstroking:NO];
    [self setLineWidth:1.0];
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
    [newGraphicsState setStrokeColorSpace:_strokeColorSpace];
    [newGraphicsState setNonStrokeColorSpace:_nonStrokeColorSpace];
    [newGraphicsState setStrokeColor:_strokeColor];
    [newGraphicsState setNonStrokeColor:_nonStrokeColor];
    [newGraphicsState setOverprintStroking:_overprintStroking];
    [newGraphicsState setOverprintNonstroking:_overprintNonstroking];
    [newGraphicsState setLineWidth:_lineWidth];
    return newGraphicsState;
}
@end
