//
//  PEPToolbarView.m
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPToolbarView.h"

@implementation PEPToolbarView

- (void)initToolsForEditPDF {
    _tools = [NSMutableArray array];
    // Add Text Edit tool
    PEPTool *textEditTool = [PEPTool create];
    NSImage *textEditImage = [NSImage imageNamed:@"cursor-text"];
    [textEditTool setImage:textEditImage];
    [textEditTool setText:@"Text"];
    [textEditTool setToolbarView:self];
    [_tools addObject:textEditTool];
    [self setNeedsDisplay:YES];
}

- (void)removeAllTools {
    [_tools removeAllObjects];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [[NSColor whiteColor] set];
    NSRectFill(self.bounds);
    
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    
    for (PEPTool *tool in _tools) {
        [tool draw:context];
    }
}

- (BOOL)mouseDownCanMoveWindow {
    return NO;
}

- (NSRect)getRectForTool:(PEPTool*)tool {
    NSRect frame = [self bounds];
    CGFloat totalWidth = 0.0;
    for (PEPTool *t in _tools) {
        CGFloat width = [t width];
        totalWidth += width;
    }
    CGFloat midX = NSMidX(frame);
    CGFloat x = midX - (totalWidth / 2);
    CGFloat y = (kToolbarHeight - kToolHeight) / 2;
    return NSMakeRect(x, y, [tool width], kToolHeight);
}
@end
