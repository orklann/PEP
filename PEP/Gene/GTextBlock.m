//
//  GTextBlock.m
//  PEP
//
//  Created by Aaron Elkins on 10/9/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GTextBlock.h"
#import "GLine.h"


@implementation GTextBlock
+ (id)create {
    GTextBlock *tb = [[GTextBlock alloc] init];
    NSMutableArray *ls = [NSMutableArray array];
    [tb setLines:ls];
    return tb;
}

- (void)setLines:(NSMutableArray*)ls {
    lines = ls;
}

- (void)addLine:(GLine*)l {
    [lines addObject:l];
}

- (NSString*)textBlockString {
    NSMutableString *s = [NSMutableString string];
    int i;
    for (i = 0; i < [lines count]; i++) {
        GLine *l = [lines objectAtIndex:i];
        [s appendString:[l lineString]];
        [s appendString:@"\n"];
    }
    return s;

}
@end
