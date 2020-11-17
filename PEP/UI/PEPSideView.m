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
    [super drawRect:dirtyRect];
    NSColor *bgColor = kDarkColor;
    [bgColor set];
    NSRectFill([self bounds]);
}

@end
