//
//  GTJText.m
//  PEP
//
//  Created by Aaron Elkins on 3/1/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GTJText.h"
#import "GGlyph.h"

@implementation GTJText
+ (id)create {
    GTJText *text = [[GTJText alloc] init];
    [text setGlyphs:[NSMutableArray array]];
    return text;
}

- (void)addGlyph:(GGlyph*)g {
    [glyphs addObject:g];
}

- (NSMutableArray *)glyphs {
    return glyphs;
}

- (void)setGlyphs:(NSMutableArray*)array {
    cached = NO;
    glyphs = array;
}

- (NSRect)frame {
    if (cached) return frame;
    NSRect frame = NSZeroRect;
    for (GGlyph *g in glyphs) {
        frame = NSUnionRect(frame, [g frame]);
    }
    cached = YES;
    return frame;
}
@end
