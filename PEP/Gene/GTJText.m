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

- (void)addGlyphs:(NSArray*)gs {
    [glyphs addObjectsFromArray:gs];
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
    NSRect totalRect= NSZeroRect;
    for (GGlyph *g in glyphs) {
        totalRect = NSUnionRect(totalRect, [g frame]);
    }
    cached = YES;
    frame = totalRect;
    return frame;
}
@end
