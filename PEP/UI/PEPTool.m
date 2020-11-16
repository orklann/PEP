//
//  PEPTool.m
//  PEP
//
//  Created by Aaron Elkins on 11/16/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPTool.h"
#import "PEPToolbarView.h"

@implementation PEPTool
+ (id)create {
    PEPTool *tool = [[PEPTool alloc] init];
    return tool;
}

- (void)setSelected:(BOOL)s {
    selected = s;
}

- (void)setToolbarView:(PEPToolbarView*)tb {
    toolbarView = tb;
}

- (void)setImage:(NSImage*)img {
    image = img;
}

- (void)setSelectedImage:(NSImage*)img {
    selectedImage = img;
}

- (void)setText:(NSString*)s {
    text = s;
}

- (void)draw:(CGContextRef)context {
    NSRect rect = [toolbarView getRectForTool:self];
    NSRect imageRect = rect;
    imageRect.size.width = kToolHeight;
    imageRect.size.height = kToolHeight;
    [image drawInRect:imageRect];
    
    NSAttributedString *attributedText = [self attributedText];
    
    NSRect textRect = imageRect;
    CGFloat width = [attributedText boundingRectWithSize:NSZeroSize options:NSStringDrawingUsesDeviceMetrics context:nil].size.width;
    textRect.origin.x += kToolHeight;
    textRect.size.width = width + 2;
    textRect.size.height = kToolHeight;
    textRect = NSInsetRect(textRect, 0, 3);
    [attributedText drawInRect:textRect];
    
    if (selected) {
        // Draw bottom line to indicate selected status
        NSRect bottomLineRect = rect;
        bottomLineRect.origin.y = 0;
        bottomLineRect.size.height = 3;
        NSColor *bottomLineColor = [NSColor colorWithRed:0.22 green:0.66 blue:0.99 alpha:1.0];
        [bottomLineColor set];
        NSRectFill(bottomLineRect);
    }
}

- (NSAttributedString*)attributedText {
    // Label font and color
    NSFont *labelFont = [NSFont systemFontOfSize:13];
    
    NSColor *labelColor = [NSColor blackColor];
    
    // Put all in attributes dictionary
    NSMutableDictionary *attributesDictionary = [NSMutableDictionary dictionary];
    [attributesDictionary setObject:labelFont forKey:NSFontAttributeName];
    [attributesDictionary setObject:labelColor forKey:NSForegroundColorAttributeName];

    // Title text
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributesDictionary];
    return attributedText;
}

- (CGFloat)width {
    CGFloat result = 0;
    CGFloat imageWidth = kToolHeight + 2;
    NSAttributedString *attributedText = [self attributedText];
    result = imageWidth + [attributedText boundingRectWithSize:NSZeroSize options:NSStringDrawingUsesDeviceMetrics context:nil].size.width;
    result += (2 * kToolWidthMargin);
    return result;
}
@end
