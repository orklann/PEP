//
//  PEPTab.m
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PEPTab.h"
#import "PEPTabView.h"

@implementation PEPTab

+ (id)create {
    PEPTab *tab = [[PEPTab alloc] init];
    return tab;
}

- (void)setTitle:(NSString*)t {
    title = t;
}

- (void)drawActive:(CGContextRef)context {
    NSRect rect = [self.tabView getRectForTab:self];
    CGFloat midX = NSMidX(rect);
    CGFloat midY = NSMidY(rect);
    CGFloat minX = NSMinX(rect);
    CGFloat minY = NSMinY(rect);
    CGFloat maxX = NSMaxX(rect);
    CGFloat maxY = NSMaxY(rect);
    
    /*
     * Fill Path
     */
    // bottom left arc
    CGContextMoveToPoint(context, minX, minY);
    CGContextAddArcToPoint(context, minX + kTabRadius, minY,
                           minX + kTabRadius, midY, kTabRadius);
    // top left arc
    CGContextAddArcToPoint(context, minX + kTabRadius, maxY,
                           midX, maxY, kTabRadius);
    // top right arc
    CGContextAddArcToPoint(context, maxX - kTabRadius, maxY,
                           maxX - kTabRadius, minY, kTabRadius);
    // bottom right arc
    CGContextAddArcToPoint(context, maxX - kTabRadius, minY,
                           maxX, minY, kTabRadius);
    CGContextSetFillColorWithColor(context, [[NSColor whiteColor] CGColor]);
    CGContextFillPath(context);
        
}

- (void)draw:(CGContextRef)context {
    [self drawActive:context];
}
@end
