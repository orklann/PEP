//
//  PEPTopView.m
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPTopView.h"

@implementation PEPTopView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSColor *bgColor = [NSColor yellowColor];
    [bgColor set];
    NSRectFill(self.bounds);
    
    // Test if views layout is right
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    CGContextSetLineWidth(context, 6.0);
    CGContextSetStrokeColorWithColor(context, [[NSColor blueColor] CGColor]);
    CGContextStrokeRect(context, self.bounds);
}

@end
