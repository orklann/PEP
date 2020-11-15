//
//  PEPTopView.m
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPTopView.h"
#import "PEPWindow.h"

@implementation PEPTopView

- (void)layoutViews {
    PEPTabView *tabView = [(PEPWindow*)self.window tabView];
    NSSize tabSize = NSMakeSize(kTabWidth * 4, kTabHeight);
    NSRect topViewBounds = [self bounds];
    CGFloat midX = NSMidX(topViewBounds);
    CGFloat x = midX - (tabSize.width / 2);
    NSRect tabRect = NSMakeRect(x, 0, tabSize.width, tabSize.height);
    [tabView setFrame:tabRect];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSColor *bgColor = [NSColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    [bgColor set];
    NSRectFill(self.bounds);
    
    // Test if views layout is right
    /*CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    CGContextSetLineWidth(context, 6.0);
    CGContextSetStrokeColorWithColor(context, [[NSColor blueColor] CGColor]);
    CGContextStrokeRect(context, self.bounds);
     */
}

@end
