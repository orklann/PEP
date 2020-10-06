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
    return w;
}

- (void)setGlyphs:(NSMutableArray *)gs {
    glyphs = gs;
}

- (void)setFrame:(NSRect)f {
    frame = f;
}

- (NSRect)frame {
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
@end
