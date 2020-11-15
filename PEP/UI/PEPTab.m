//
//  PEPTab.m
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPTab.h"

@implementation PEPTab

+ (id)create {
    PEPTab *tab = [[PEPTab alloc] init];
    return tab;
}

- (void)setTitle:(NSString*)t {
    title = t;
}

- (void)setRect:(NSRect)r {
    rect = r;
}

- (void)draw:(CGContextRef)context {
    NSLog(@"PEPTab draw, rect: %@", NSStringFromRect(rect));
}
@end
