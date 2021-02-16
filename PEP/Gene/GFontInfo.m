//
//  GFontInfo.m
//  PEP
//
//  Created by Aaron Elkins on 2/16/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GFontInfo.h"

@implementation GFontInfo
+ (id)create {
    GFontInfo *o = [[GFontInfo alloc] init];
    return o;
}

- (CGFloat)getCharWidth:(unichar)charCode {
    NSUInteger index = charCode - self.firstChar;
    if (index >= [self.widths count] || index < 0) {
        NSLog(@"Debug: missing width: %d", (int)[self missingWidth]);
        return (CGFloat)([self missingWidth] / 1000.0);
    }
    NSNumber *widthNumber = [self.widths objectAtIndex:index];
    CGFloat width = [widthNumber floatValue];
    return (CGFloat)(width / 1000.0);
}
@end
