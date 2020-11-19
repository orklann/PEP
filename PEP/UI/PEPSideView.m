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
    familyList = [[NSPopUpButton alloc] initWithFrame:NSZeroRect];
    [self addSubview:familyList];
    [familyList setTarget:self];
    [familyList setAction:@selector(fontFamiliesSelectionDidChange:)];
    [self reloadDefaultFontFamilies];
    
    // Style label
    styleLabel = [self makeTitleLableWithText:@"Style"];
    [self addSubview:styleLabel];
    
    // Style list
    styleList = [[NSPopUpButton alloc] initWithFrame:NSZeroRect];
    [self addSubview:styleList];
    [self reloadStyleList];
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
    NSRect fontListFrame = fontLabelFrame;
    fontListFrame.size.height = 32;
    fontListFrame.origin.y += 24;
    [familyList setFrame:fontListFrame];
    
    // Style label
    NSRect styleLabelFrame = fontListFrame;
    styleLabelFrame.size.height = 24;
    styleLabelFrame.origin.y += 32;
    [styleLabel setFrame:styleLabelFrame];
    
    // Style list
    NSRect styleListFrame = styleLabelFrame;
    styleListFrame.size.height = 32;
    styleListFrame.origin.y += 24;
    [styleList setFrame:styleListFrame];
}

- (void)reloadDefaultFontFamilies {
    NSArray *fontfamilies = allFontFamiliesInSystem();
    [familyList removeAllItems];
    [familyList addItemsWithTitles:fontfamilies];
    
    // Construct fontFamilyDictionary
    NSFontManager *fm = [NSFontManager sharedFontManager];
    familyDictionary = [NSMutableDictionary dictionary];
    for (NSString *family in fontfamilies) {
        NSArray *familyMembers;
        familyMembers = [fm availableMembersOfFontFamily:family];
        NSMutableDictionary *memberDictionary = [NSMutableDictionary dictionary];
        for (NSArray *member in familyMembers) {
            [memberDictionary setObject:[member objectAtIndex:0] forKey:[member objectAtIndex:1]];
        }
        [familyDictionary setObject:memberDictionary forKey:family];
    }
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

- (IBAction)fontFamiliesSelectionDidChange:(id)sender {
    [self reloadStyleList];
}

- (void)reloadStyleList {
    NSString *selectedFamily = [familyList titleOfSelectedItem];
    NSDictionary *selectedFamilyDictionary = [familyDictionary objectForKey:selectedFamily];
    NSArray *styles = [selectedFamilyDictionary allKeys];
    [styleList removeAllItems];
    [styleList addItemsWithTitles:styles];
}
@end
