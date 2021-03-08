//
//  GWord.m
//  PEP
//
//  Created by Aaron Elkins on 10/6/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GWord.h"
#import "GGlyph.h"
@implementation GWord

+ (id)create {
    GWord *w = [[GWord alloc] init];
    NSMutableArray *gs = [NSMutableArray array];
    [w setGlyphs:gs];
    [w setWordDistance:kNoWordDistance];
    return w;
}

- (void)setGlyphs:(NSMutableArray *)gs {
    glyphs = gs;
}

- (void)setFrame:(NSRect)f {
    frame = f;
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

- (NSMutableArray*)glyphs {
    return glyphs;
}

- (void)addGlyph:(GGlyph*)g {
    [glyphs addObject:g];
}

- (NSString*)wordString {
    NSMutableString *s = [NSMutableString string];
    int i;
    for (i = 0; i < [glyphs count]; i++) {
        [s appendString:[[glyphs objectAtIndex:i] content]];
    }
    return s;
}

/* Return width of a word, this is different from the width of the frame of a
 * word, we calculate this width by adding all width of glyphs in it.
 */
- (CGFloat)getWordWidth {
    CGFloat result = 0;
    for (GGlyph *g in [self glyphs]) {
        result += g.width;
    }
    return result;
}
@end
