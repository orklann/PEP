//
//  PEPTopView.m
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPTopView.h"
#import "PEPWindow.h"
#import "PEPConstants.h"

@implementation PEPTopView

- (void)layoutViews {
    // Tab view
    PEPTabView *tabView = [(PEPWindow*)self.window tabView];
    NSSize tabSize = NSMakeSize(kTabWidth * 4, kTabHeight);
    NSRect topViewBounds = [self bounds];
    CGFloat midX = NSMidX(topViewBounds);
    CGFloat x = midX - (tabSize.width / 2);
    CGFloat y = kToolbarHeight; // toolbar height offset
    NSRect tabRect = NSMakeRect(x, y, tabSize.width, tabSize.height);
    [tabView setFrame:tabRect];
    
    // Toolbar view
    PEPToolbarView *toolbarView = [(PEPWindow*)self.window toolbarView];
    NSRect toolbarRect = topViewBounds;
    toolbarRect.size.height = kToolbarHeight;
    toolbarRect.origin = NSMakePoint(0, 0);
    [toolbarView setFrame:toolbarRect];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSColor *bgColor = kDarkColor;
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
