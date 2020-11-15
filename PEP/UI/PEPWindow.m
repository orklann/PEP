//
//  PEPWindow.m
//  PEP
//
//  Created by Aaron Elkins on 11/14/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPWindow.h"

@implementation PEPWindow

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
    
    needToMoveCloseButton = YES;
    needToMoveMiniaturizeButton = YES;
    needToMoveZoomButton = YES;
    
    topView = [[PEPTopView alloc] initWithFrame:NSZeroRect];
    [self.contentView addSubview:topView];
    
    tabView = [[PEPTabView alloc] initWithFrame:NSZeroRect];
    [topView addSubview:tabView];
    [tabView initTabs];
    
    toolbarView = [[PEPToolbarView alloc] initWithFrame:NSZeroRect];
    [topView addSubview:toolbarView];
    
    [self layoutViews];
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
    
    // Scroll View
    NSRect scrollViewFrame = contentViewFrame;
    scrollViewFrame.size.height = contentViewFrame.size.height - kTopViewHeight;
    [self.scrollView setFrame:scrollViewFrame];
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
