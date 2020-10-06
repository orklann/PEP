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
    return w;
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
@end
