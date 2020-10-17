//
//  GTextBlock.m
//  PEP
//
//  Created by Aaron Elkins on 10/9/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GTextBlock.h"
#import "GLine.h"
#import "GWord.h"
#import "GGlyph.h"

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

- (NSMutableArray*)glyphs {
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
    [self makeIndexInfoForGlyphs];
    [self setLineIndexForGlyphs];
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

- (void)makeIndexInfoForGlyphs {
    NSArray *glyphs = [self glyphs];
    int i;
    for (i = 0; i < [glyphs count]; i++) {
        GGlyph *g = [glyphs objectAtIndex:i];
        g.indexOfLine = i;
    }
}

- (void)setLineIndexForGlyphs {
    NSArray *lines = [self lines];
    int i;
    for (i = 0; i < [lines count]; i++) {
        GLine *l = [lines objectAtIndex:i];
        NSArray *glyphsForLine = [l glyphs];
        int j;
        for (j = 0; j < [glyphsForLine count]; j++) {
            GGlyph *g = [glyphsForLine objectAtIndex:j];
            [g setLineIndex:i];
        }
    }
}

- (int)getLineOfGlyphIndex:(int)index {
    int i;
    int indexFull = 0;
    for (i = 0; i < [lines count]; i++) {
        GLine *l = [lines objectAtIndex:i];
        int j;
        for (j = 0; j < [[l words] count]; j++) {
            GWord *w = [[l words] objectAtIndex:j];
            int k;
            for (k = 0; k < [[w glyphs] count]; k++) {
                if (index == indexFull) {
                    return i;
                }
                indexFull++;
            }
        }
    }
    return -1;
}

- (int)indexOfLine:(int)line forFullGlyphsIndex:(int)index {
    int i;
    int indexFull = 0;
    for (i = 0; i < [lines count]; i++) {
        GLine *l = [lines objectAtIndex:i];
        int j;
        int indexInLine = 0;
        for (j = 0; j < [[l words] count]; j++) {
            GWord *w = [[l words] objectAtIndex:j];
            int k;
            for (k = 0; k < [[w glyphs] count]; k++) {
                if (index == indexFull) {
                    return indexInLine;
                }
                indexFull++;
                indexInLine++;
            }
        }
    }
    return -1;
}
@end
