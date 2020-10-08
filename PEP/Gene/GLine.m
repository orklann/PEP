//
//  GLine.m
//  PEP
//
//  Created by Aaron Elkins on 10/8/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GLine.h"
#import "GWord.h"

@implementation GLine
+ (id)create {
    GLine *l = [[GLine alloc] init];
    NSMutableArray *ws = [NSMutableArray array];
    [l setWords:ws];
    return l;
}

- (void)setWords:(NSMutableArray*)ws {
    words = ws;
}

- (void)addWord:(GWord*)w {
    [words addObject:w];
}

- (NSMutableArray*)words {
    return words;
}

- (NSRect)frame {
    CGFloat startX = INFINITY, startY = INFINITY, endX = -INFINITY, endY = -INFINITY;
    int i;
    for (i = 0; i < [words count]; i++) {
        GWord *w = [words objectAtIndex:i];
        NSRect f = [w frame];
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
    for (i = 0; i < [words count]; i++) {
        GWord *w = [words objectAtIndex:i];
        [s appendString:[w wordString]];
    }
    return s;
}
@end
