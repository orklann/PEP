//
//  PEPToolbarView.m
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPToolbarView.h"

@implementation PEPToolbarView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [[NSColor whiteColor] set];
    NSRectFill(self.bounds);
}

@end
