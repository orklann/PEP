//
//  PEPWindow.m
//  PEP
//
//  Created by Aaron Elkins on 11/14/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPWindow.h"

@implementation PEPWindow

- (PEPSideView*)sideView {
    return sideView;
}

- (PEPTabView*)tabView {
    return tabView;
}

- (PEPToolbarView*)toolbarView {
    return toolbarView;
}

- (void)awakeFromNib {
    [self setTitle:@""];
    [self setTitlebarAppearsTransparent:YES];
    self.movableByWindowBackground = YES;
    [self setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameAqua]];
    
    needToMoveCloseButton = YES;
    needToMoveMiniaturizeButton = YES;
    needToMoveZoomButton = YES;
    
    self.scrollView = [[NSScrollView alloc] initWithFrame:[[self contentView] frame]];

    // configure the scroll view
    [self.scrollView setBorderType:NSNoBorder];
    [self.scrollView setHasVerticalScroller:YES];

    // embed your custom view in the scroll view
    self.doc = [[GDocument alloc] initWithFrame:[[self contentView] frame]];
    [self.scrollView setDocumentView:self.doc];
    [self.contentView addSubview:self.scrollView];
    
    
    topView = [[PEPTopView alloc] initWithFrame:NSZeroRect];
    [self.contentView addSubview:topView];
    
    tabView = [[PEPTabView alloc] initWithFrame:NSZeroRect];
    [topView addSubview:tabView];
    [tabView initTabs];
    
    toolbarView = [[PEPToolbarView alloc] initWithFrame:NSZeroRect];
    [topView addSubview:toolbarView];
    
    sideView = [[PEPSideView alloc] initWithFrame:NSZeroRect];
    [self.contentView addSubview:sideView];
    [sideView initAllViews];
    
    [self layoutViews];
    
    // Initialize GDocument at last to make sure scrollToTop work correctly
    [self.doc awakeFromNib];
}

/*
 * Layout all views
 */
- (void)layoutViews {
    // Top View
    NSRect contentViewFrame = [self.contentView frame];
    NSRect topViewFrame = contentViewFrame;
    topViewFrame.size.height = kTopViewHeight;
    topViewFrame.origin.y = contentViewFrame.size.height - kTopViewHeight;
    [topView setFrame:topViewFrame];

    // Layout tab view, toolbar view
    [topView layoutViews];
    
    if ([self.doc textEditor]) {
        // Scroll View, but make space for right side view
        NSRect scrollViewFrame = contentViewFrame;
        scrollViewFrame.size.height = contentViewFrame.size.height - kTopViewHeight;
        scrollViewFrame.size.width -= kSideViewWidth;
        [self.scrollView setFrame:scrollViewFrame];
        NSRect docRect = scrollViewFrame;
        // Make sure to resize GDocument (Scroll view's document view)
        docRect.origin = NSZeroPoint;
        [self.doc setFrame:docRect];
        
        // Side View
        NSRect sideViewFrame = contentViewFrame;
        sideViewFrame.size.height = contentViewFrame.size.height - kTopViewHeight;
        sideViewFrame.size.width = kSideViewWidth;
        sideViewFrame.origin.x = NSMaxX(scrollViewFrame);
        [sideView setFrame:sideViewFrame];
        [sideView layoutViews];
    } else {
        // Only scroll View
        NSRect scrollViewFrame = contentViewFrame;
        scrollViewFrame.size.height = contentViewFrame.size.height - kTopViewHeight;
        [self.scrollView setFrame:scrollViewFrame];
        
        // Hide side view
        [sideView setFrame:NSZeroRect];
    }
}

- (void)layoutIfNeeded {
    [super layoutIfNeeded];
    [self moveButtonOfType:NSWindowCloseButton];
    [self moveButtonOfType:NSWindowMiniaturizeButton];
    [self moveButtonOfType:NSWindowZoomButton];
    [self layoutViews];
}

- (void)moveButtonOfType:(NSWindowButton) b {
    NSButton *button = [self standardWindowButton:b];
    if (b == NSWindowCloseButton) {
        if (needToMoveCloseButton) {
            needToMoveCloseButton = NO;
            [self moveButtonDown:button];
            [self moveButtonRight:button];
        }
    } else if (b == NSWindowMiniaturizeButton) {
        if (needToMoveMiniaturizeButton) {
            needToMoveMiniaturizeButton = NO;
            [self moveButtonDown:button];
            [self moveButtonRight:button];
        }
    } else if (b == NSWindowZoomButton) {
        if (needToMoveZoomButton) {
            needToMoveZoomButton = NO;
            [self moveButtonDown:button];
            [self moveButtonRight:button];
        }
    }
    
}

- (void)moveButtonDown:(NSView*)button {
    [button setFrameOrigin:(NSMakePoint(button.frame.origin.x, button.frame.origin.y - kMoveButtonDelta))];
}

- (void)moveButtonRight:(NSView*)button {
    [button setFrameOrigin:(NSMakePoint(button.frame.origin.x + kMoveButtonDelta, button.frame.origin.y))];
}

- (void)needToMoveButtons {
    needToMoveCloseButton = YES;
    needToMoveMiniaturizeButton = YES;
    needToMoveZoomButton = YES;
}
@end
