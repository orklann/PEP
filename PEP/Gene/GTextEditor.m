//
//  GTextEditor.m
//  PEP
//
//  Created by Aaron Elkins on 10/14/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GTextEditor.h"
#import "GPage.h"
#import "GTextBlock.h"
#import "GGlyph.h"
#import "GDocument.h"

@implementation GTextEditor
+ (id)textEditorWithPage:(GPage *)p textBlock:(GTextBlock *)tb {
    GTextEditor *editor = [[GTextEditor alloc] initWithPage:p textBlock:tb];
    return editor;
}

- (GTextEditor*)initWithPage:(GPage *)p textBlock:(GTextBlock*)tb {
    self = [super init];
    self.page = p;
    textBlock = tb;
    insertionPointIndex = 0;
    self.drawInsertionPoint = YES;
    blinkTimer = [NSTimer scheduledTimerWithTimeInterval:0.6 repeats:YES block:^(NSTimer * _Nonnull timer) {
        GDocument *doc = (GDocument*)[(GPage*)self.page doc];
        if (self.drawInsertionPoint) {
            self.drawInsertionPoint = NO;
        } else {
            self.drawInsertionPoint = YES;
        }
        [doc setNeedsDisplay:YES];
    }];
    return self;
}

- (void)draw:(CGContextRef)context {
    NSLog(@"GTextEditor insertion point index: %d", insertionPointIndex);
    if (self.drawInsertionPoint) {
        NSRect rect = [self getInsertionPoint];
        CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);
        CGContextFillRect(context, rect);
    }
}

- (NSRect)getInsertionPoint {
    NSArray *glyphs = [textBlock glyphs];
    GGlyph *g = [glyphs objectAtIndex:insertionPointIndex];
    NSRect rect = [g frame];
    NSRect ret;
    if (insertionPointIndex < [glyphs count] - 1) {
        CGFloat minX = NSMinX(rect);
        CGFloat minY = NSMinY(rect);
        CGFloat height = NSHeight(rect);
        ret = NSMakeRect(minX, minY, 1, height);
    } else {
        CGFloat maxX = NSMaxX(rect);
        CGFloat minY = NSMinY(rect);
        CGFloat height = NSHeight(rect);
        ret = NSMakeRect(maxX, minY, 1, height);
    }
    return ret;
}
@end
