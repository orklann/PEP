//
//  GGlyph.m
//  PEP
//
//  Created by Aaron Elkins on 10/5/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GGlyph.h"

@implementation GGlyph
+ (id)create {
    GGlyph *g = [[GGlyph alloc] init];
    return g;
}

- (void)setFrame:(NSRect)f {
    frame = f;
}

// return frame in GPage coordinate
// In some case, we need view coordinate, just call [GPage rectFromPageToView:]
// to convert to view coordinate
- (NSRect)frame {
    return frame;
}

- (void)setPoint:(NSPoint)p {
    point = p;
}

- (NSPoint)point {
    return point;
}

- (void)setContent:(NSString*)s {
    content = s;
}

- (NSString*)content {
    return content;
}
@end
