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
#import "PEPTabDelegate.h"

@implementation PEPTab

+ (id)create {
    PEPTab *tab = [[PEPTab alloc] init];
    return tab;
}

- (void)setTitle:(NSString*)t {
    title = t;
}

- (NSString*)title {
    return title;
}

- (void)setActive:(BOOL)flag {
    if (flag && !active) {
        if ([_delegate respondsToSelector:@selector(tabDidActive:)]) {
            [_delegate tabDidActive:self];
        }
    }
    active = flag;
}

- (void)drawTitle:(CGContextRef)context {
    NSRect rect = [self.tabView getRectForTab:self];
    
    // Paragraph Style
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    
    // Label font and color
    NSFont *labelFont = [NSFont systemFontOfSize:13];
    
    NSColor *labelColor;
    if (active) {
        labelColor = [NSColor blackColor];
    } else {
        labelColor = [NSColor whiteColor];
    }

    // Put all in attributes dictionary
    NSMutableDictionary *attributesDictionary = [NSMutableDictionary dictionary];
    [attributesDictionary setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    [attributesDictionary setObject:labelFont forKey:NSFontAttributeName];
    [attributesDictionary setObject:labelColor forKey:NSForegroundColorAttributeName];

    // Title text
    NSAttributedString *titleText = [[NSAttributedString alloc] initWithString:title attributes:attributesDictionary];
    NSRect titleRect = NSInsetRect(rect, 8, 6);
    [titleText drawInRect:titleRect];
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
    if (active) {
        [self drawActive:context];
    }
    [self drawTitle:context];
}
@end
