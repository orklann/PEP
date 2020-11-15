//
//  PEPTabview.m
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPTabView.h"
#import "PEPConstants.h"

@implementation PEPTabView

- (void)initTabs {
    tabs = [NSMutableArray array];
    PEPTab *tab1 = [PEPTab create];
    [tab1 setTabView:self];
    [tabs addObject:tab1];
    [self setNeedsDisplay:YES];
}

- (NSRect)getRectForTab:(PEPTab*)tab {
    NSRect tabViewBounds = [self bounds];
    CGFloat tabViewX = tabViewBounds.origin.x;
    int index = (int)[tabs indexOfObject:tab];
    NSSize size = NSMakeSize(kTabWidth, kTabHeight);
    CGFloat x = tabViewX + (index * kTabWidth);
    CGFloat y = 0;
    return NSMakeRect(x, y, size.width, size.height);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSColor *bgColor = kDarkColor;
    [bgColor set];
    NSRectFill(self.bounds);
    
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    
    // Draw tabs
    for (PEPTab *tab in tabs) {
        [tab draw:context];
    }
}

@end
