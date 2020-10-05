//
//  GTextParser.m
//  PEP
//
//  Created by Aaron Elkins on 10/5/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GTextParser.h"

@implementation GTextParser
+ (id)create {
    GTextParser *tp = [[GTextParser alloc] init];
    NSMutableArray *gs = [NSMutableArray array];
    [tp setGlyphs:gs];
    return tp;
}

- (void)setGlyphs:(NSMutableArray*)gs {
    glyphs = gs;
}

- (NSMutableArray*)glyphs {
    return glyphs;
}
@end
