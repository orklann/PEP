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

@property (readwrite) GColorSpace *colorSpace;
@property (readwrite) NSColor *strokeColor;
@property (readwrite) NSColor *nonStrokeColor;

+ (id)create;
- (void)initState;
- (void)setCTM:(CGAffineTransform)tf;
- (CGAffineTransform)ctm;
- (GGraphicsState*)clone;
@end

NS_ASSUME_NONNULL_END
