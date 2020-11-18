//
//  PEPSideView.m
//  PEP
//
//  Created by Aaron Elkins on 11/17/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPSideView.h"
#import "PEPConstants.h"
#import "PEPMisc.h"

@implementation PEPSideView

- (void)drawRect:(NSRect)dirtyRect {
    // The same color with NSScrollView's border color,
    // But we hard code the side view top border color here
    // TODO: A smarter way to get the system default border color
    [[NSColor colorWithRed:0.90 green:0.90 blue:0.90 alpha:1] set];
    NSRectFill([self bounds]);

    NSRect newRectWithTopBorder = [self bounds];
    newRectWithTopBorder.origin.y += 1;
    [[NSColor whiteColor] set];
    NSRectFill(newRectWithTopBorder);
}

- (BOOL)isOpaque {
    return YES;
}

- (void)initAllViews {
    // View settings
    [self setAlphaValue:1.0];
    
    // Font label
    fontLabel = [self makeTitleLableWithText:@"Font"];
    [self addSubview:fontLabel];
    
    // Font list
    fontsList = [[NSPopUpButton alloc] initWithFrame:NSZeroRect];
    [self addSubview:fontsList];
    [self setFontListItems];
}

- (void)layoutViews {
    [self layoutFontView];
}

- (void)layoutFontView {
    NSRect sideViewFrame = [self marginBounds];
    
    // Font label
    NSRect fontLabelFrame = sideViewFrame;
    fontLabelFrame.size.height = 24;
    fontLabelFrame.origin.y = 12;
    [fontLabel setFrame:fontLabelFrame];
    
    // Font list
    NSRect fontListFrame = sideViewFrame;
    fontListFrame.size.height = 32;
    fontListFrame.origin.y = 38;
    [fontsList setFrame:fontListFrame];
    
    // TODO: List all font styles for each font
    // Need another NSPopupButton here
    // USE: use font name and comparing to fonts list to get all styles for a font name
    // NSArray *fonts = [[NSFontManager sharedFontManager] availableFonts];
    
}

- (void)setFontListItems {
    NSArray *fonts = allFontsInSystem();
    [fontsList removeAllItems];
    [fontsList addItemsWithTitles:fonts];
}

- (BOOL)isFlipped {
    return YES;
}

- (NSRect)marginBounds {
    return NSInsetRect(self.bounds, 12, 0);
}

- (NSTextField*)makeTitleLableWithText:(NSString*)text {
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSZeroRect];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setStringValue:text];
    [label setDrawsBackground:NO];
    [label setBezeled:NO];
    [label setFont:[NSFont labelFontOfSize:15]];
    return label;
}
@end
