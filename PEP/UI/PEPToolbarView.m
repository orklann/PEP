//
//  PEPToolbarView.m
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPToolbarView.h"
#import "PEPConstants.h"

@implementation PEPToolbarView

- (void)initToolsForEditPDF {
    _tools = [NSMutableArray array];
    // Add Text Edit tool
    PEPTool *textEditTool = [PEPTool create];
    NSImage *textEditImage = [NSImage imageNamed:@"cursor-text"];
    [textEditTool setImage:textEditImage];
    [textEditTool setText:kTextEditToolText];
    [textEditTool setToolbarView:self];
    [textEditTool setDelegate:[NSApp delegate]];
    [textEditTool setSelected:YES];
    [_tools addObject:textEditTool];
    
    // Add Image tool
    PEPTool *imageTool = [PEPTool create];
    NSImage *imageToolImage = [NSImage imageNamed:@"image"];
    [imageTool setImage:imageToolImage];
    [imageTool setText:kImageToolText];
    [imageTool setToolbarView:self];
    [imageTool setDelegate:[NSApp delegate]];
    [imageTool setSelected:NO];
    [_tools addObject:imageTool];
    
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
        totalWidth += kToolMargin;
    }
    CGFloat midX = NSMidX(frame);
    CGFloat x = midX - (totalWidth / 2);
    
    int index = (int)[_tools indexOfObject:tool];
    int i;
    for (i = 0; i < index; i++)  {
        PEPTool *tool = [_tools objectAtIndex:i];
        x += [tool width];
        x += kToolMargin;
    }
    
    CGFloat y = (kToolbarHeight - kToolHeight) / 2;
    return NSMakeRect(x, y, [tool width], kToolHeight);
}
@end
