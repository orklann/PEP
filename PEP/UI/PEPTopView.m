//
//  PEPTopView.m
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPTopView.h"

@implementation PEPTopView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSColor *bgColor = [NSColor yellowColor];
    [bgColor set];
    NSRectFill(self.bounds);
}

@end
