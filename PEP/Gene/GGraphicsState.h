//
//  GGraphicsState.h
//  PEP
//
//  Created by Aaron Elkins on 9/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "GColorSpace.h"

NS_ASSUME_NONNULL_BEGIN


@interface GGraphicsState : NSObject {
    CGAffineTransform ctm;
}

@property (readwrite) GColorSpace *strokeColorSpace;
@property (readwrite) GColorSpace *nonStrokeColorSpace;
@property (readwrite) NSColor *strokeColor;
@property (readwrite) NSColor *nonStrokeColor;
@property (readwrite) BOOL overprintStroking;
@property (readwrite) BOOL overprintNonstroking;

+ (id)create;
- (void)initState;
- (void)setCTM:(CGAffineTransform)tf;
- (CGAffineTransform)ctm;
- (GGraphicsState*)clone;
@end

NS_ASSUME_NONNULL_END
