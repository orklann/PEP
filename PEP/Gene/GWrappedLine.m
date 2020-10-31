//
//  GWrappedLine.m
//  PEP
//
//  Created by Aaron Elkins on 10/31/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GWrappedLine.h"

#import "GGlyph.h"

@implementation GWrappedLine
+ (id)create {
    GWrappedLine *l = [[GWrappedLine alloc] init];
    NSMutableArray *gs = [NSMutableArray array];
    [l setGlyphs:gs];
    return l;
}

- (void)setGlyphs:(NSMutableArray*)gs {
    glyphs = gs;
}

- (NSArray*)glyphs {
    return glyphs;
}

- (void)addGlyph:(GGlyph*)g {
    [glyphs addObject:g];
}

- (NSRect)frame {
    CGFloat startX = INFINITY, startY = INFINITY, endX = -INFINITY, endY = -INFINITY;
    int i;
    for (i = 0; i < [glyphs count]; i++) {
        GGlyph *g = [glyphs objectAtIndex:i];
        NSRect f = [g frame];
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

- (NSString*)lineString {
    NSMutableString *s = [NSMutableString string];
    int i;
    for (i = 0; i < [glyphs count]; i++) {
        [s appendString:[[glyphs objectAtIndex:i] content]];
    }
    return s;
}

- (int)indexforGlyph:(GGlyph*)g {
    int result = -1;
    int i;
    for (i = 0 ; i < [glyphs count]; i++) {
        GGlyph *glyph = [glyphs objectAtIndex:i];
        if ([glyph isEqualTo:g]) {
            result = i;
            return result;
        }
    }
    return result;
}

- (GGlyph*)getGlyphByIndex:(int)index {
    return [glyphs objectAtIndex:index];
}
@end
