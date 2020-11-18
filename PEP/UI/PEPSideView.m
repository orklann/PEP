//
//  PEPSideView.m
//  PEP
//
//  Created by Aaron Elkins on 11/17/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPSideView.h"
#import "PEPConstants.h"

@implementation PEPSideView

- (void)drawRect:(NSRect)dirtyRect {
    // The same color with NSScrollView's border color
    [[NSColor colorWithRed:0.90 green:0.90 blue:0.90 alpha:1] set];
    NSRectFill([self bounds]);

    NSRect newRectWithTopBorder = [self bounds];
    newRectWithTopBorder.origin.y += 1;
    [[NSColor whiteColor] set];
    NSRectFill(newRectWithTopBorder);
}

- (BOOL)isOpaque {
    return YES;
}

- (void)initAllViews {
    // View settings
    [self setAlphaValue:1.0];
    
    fontLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
    [fontLabel setEditable:NO];
    [fontLabel setSelectable:NO];
    [fontLabel setStringValue:@"Font"];
    [fontLabel setDrawsBackground:NO];
    [fontLabel setBezeled:NO];
    [fontLabel setFont:[NSFont labelFontOfSize:15]];
    [self addSubview:fontLabel];
}

- (void)layoutViews {
    [self layoutFontView];
}

- (void)layoutFontView {
    NSRect sideViewFrame = [self marginBounds];
    NSRect fontLabelFrame = sideViewFrame;
    fontLabelFrame.size.height = 24;
    fontLabelFrame.origin.y = 6;
    [fontLabel setFrame:fontLabelFrame];
}

- (BOOL)isFlipped {
    return YES;
}

- (NSRect)marginBounds {
    return NSInsetRect(self.bounds, 12, 0);
}
@end
