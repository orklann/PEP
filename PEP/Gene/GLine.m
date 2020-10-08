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
