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
    // Annotate tab
    PEPTab *tab1 = [PEPTab create];
    [tab1 setTabView:self];
    [tab1 setTitle:kAnnotateTabTitle];
    [tab1 setActive:YES];
    [tab1 setDelegate:NSApp.delegate];
    [tabs addObject:tab1];
    
    // Edit PDF tab
    PEPTab *tab2 = [PEPTab create];
    [tab2 setTabView:self];
    [tab2 setTitle:kEditPDFTabTitle];
    [tab2 setActive:NO];
    [tab2 setDelegate:NSApp.delegate];
    [tabs addObject:tab2];
    
    // Draw tab
    PEPTab *tab3 = [PEPTab create];
    [tab3 setTabView:self];
    [tab3 setTitle:kDrawTabTitle];
    [tab3 setActive:NO];
    [tab3 setDelegate:NSApp.delegate];
    [tabs addObject:tab3];
    
    // Favorites tab
    PEPTab *tab4 = [PEPTab create];
    [tab4 setTabView:self];
    [tab4 setTitle:kFavoritesTabTitle];
    [tab4 setActive:NO];
    [tab4 setDelegate:NSApp.delegate];
    [tabs addObject:tab4];
    
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

- (void)mouseDown:(NSEvent *)event {
    NSPoint location = [event locationInWindow];
    NSPoint point = [self convertPoint:location fromView:nil];
    
    for (PEPTab *tab in tabs) {
        NSRect tabRect = [self getRectForTab:tab];
        if (NSPointInRect(point, tabRect)) {
            [tab setActive:YES];
        } else {
            [tab setActive:NO];
        }
    }
    [self setNeedsDisplay:YES];
}

// Empty implementations to prevent mouse event pass to super view,
// So that dragging Tab View will not drag the window.
- (void)mouseDragged:(NSEvent*)event {}
- (void)mouseUp:(NSEvent*)event {}
- (void)mouseExited:(NSEvent *)event {}
- (void)mouseMoved:(NSEvent *)event {}
- (void)mouseEntered:(NSEvent *)event {}

- (BOOL)mouseDownCanMoveWindow {
    return NO;
}
@end
