//
//  GTextBlock.m
//  PEP
//
//  Created by Aaron Elkins on 10/9/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GTextBlock.h"
#import "GLine.h"


@implementation GTextBlock
+ (id)create {
    GTextBlock *tb = [[GTextBlock alloc] init];
    NSMutableArray *ls = [NSMutableArray array];
    [tb setLines:ls];
    return tb;
}

- (NSMutableArray*)lines {
    return lines;
}

- (NSArray*)glyphs {
    NSMutableArray *glyphs = [NSMutableArray array];
    int i;
    for (i = 0; i < [lines count]; i++) {
        GLine *l = [lines objectAtIndex:i];
        [glyphs addObjectsFromArray:[l glyphs]];
    }
    return glyphs;
}

- (void)setLines:(NSMutableArray*)ls {
    lines = ls;
}

- (void)addLine:(GLine*)l {
    [lines addObject:l];
}

- (NSRect)frame {
    CGFloat startX = INFINITY, startY = INFINITY, endX = -INFINITY, endY = -INFINITY;
    int i;
    for (i = 0; i < [lines count]; i++) {
        GLine *l = [lines objectAtIndex:i];
        NSRect f = [l frame];
        CGFloat xMin = NSMinX(f);
        CGFloat yMin = NSMinY(f);
        CGFloat xMax = NSMaxX(f);
        CGFloat yMax = NSMaxY(f);
        startX = xMin <= startX ? xMin : startX;
        startY = yMin <= startY ? yMin : startY;
        endX = xMax >= endX ? xMax : endX;
        endY = yMax >= endY ? yMax : endY;
    }
    frame = NSMakeRect(startX, startY, fabs(endX - startX), fabs(endY - startY));
    return frame;
}

- (NSString*)textBlockString {
    NSMutableString *s = [NSMutableString string];
    int i;
    for (i = 0; i < [lines count]; i++) {
        GLine *l = [lines objectAtIndex:i];
        [s appendString:[l lineString]];
    }
    return s;
}

- (NSString*)textBlockStringWithLineFeed {
    NSMutableString *s = [NSMutableString string];
    int i;
    for (i = 0; i < [lines count]; i++) {
        GLine *l = [lines objectAtIndex:i];
        [s appendString:[l lineString]];
        [s appendString:@"\n"];
    }
    return s;
}
@end
