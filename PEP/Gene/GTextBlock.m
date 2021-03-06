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
#import "GTextParser.h"

@implementation GTextBlock
+ (id)create {
    GTextBlock *tb = [[GTextBlock alloc] init];
    NSMutableArray *ls = [NSMutableArray array];
    [tb setLines:ls];
    [tb setCached:NO];
    return tb;
}

- (NSMutableArray*)lines {
    return lines;
}

- (void)removeGlyph:(GGlyph*)gl {
    for (GLine *l in lines) {
        for (GWord *w in [l words]) {
            for (GGlyph *g in [w glyphs]) {
                if ([g isEqualTo:gl]) {
                    [[w glyphs] removeObject:gl];
                    return ;
                }
            }
        }
    }
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

- (NSArray*)words {
    NSArray *words = [NSMutableArray array];
    NSMutableArray *lines = [self lines];
    int i;
    for (i = 0; i < [lines count]; ++i) {
        GLine *l = [lines objectAtIndex:i];
        words = [words arrayByAddingObjectsFromArray:[l words]];
    }
    return words;
}

- (void)setCached:(BOOL)c {
    cached = c;
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
    if (cached) return frame;
    cached = YES;
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
        g.indexOfBlock = i;
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

- (int)getLineIndex:(int)index {
    //
    // Get line index by index in text block glyphs
    //
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
    return (int)[lines count] - 1;
}

- (GLine*)getLineByGlyph:(GGlyph*)g {
    NSArray *gs = [self glyphs];
    int index = (int)[gs indexOfObject:g];
    if (index == -1) {
        return nil;
    }
    
    int lineIndex = [self getLineIndex:index];
    NSArray *lines = [self lines];
    GLine *l = [lines objectAtIndex:lineIndex];
    return l;
}

- (int)getGlyphIndexInLine:(int)index {
    //
    // Get glyph index in line by index in text block glyphs
    //
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

- (GTextBlock*)textBlockByAppendingGlyph:(GGlyph*)glyph {
    NSMutableArray *glyphs = [self glyphs];
    [glyphs addObject:glyph];
    GTextParser *textParser = [GTextParser create];
    [textParser setUseTJTexts:NO];
    [textParser setGlyphs:glyphs];
    GTextBlock *tb = [textParser mergeLinesToTextblock];
    return tb;
}

- (GTextBlock*)textBlockByRemovingGlyph:(GGlyph*)glyph {
    NSMutableArray *glyphs = [self glyphs];
    [glyphs removeObject:glyph];
    GTextParser *textParser = [GTextParser create];
    [textParser setUseTJTexts:NO];
    [textParser setGlyphs:glyphs];
    GTextBlock *tb = [textParser mergeLinesToTextblock];
    return tb;
}
@end
