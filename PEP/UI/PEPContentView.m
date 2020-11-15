//
//  PEPView.m
//  PEP
//
//  Created by Aaron Elkins on 11/14/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPContentView.h"

@implementation PEPContentView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    NSColor *bgColor = [NSColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    [bgColor set];
    NSRectFill([self bounds]);
}

@end
