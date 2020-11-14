//
//  PEPWindow.m
//  PEP
//
//  Created by Aaron Elkins on 11/14/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPWindow.h"

@implementation PEPWindow
- (void)awakeFromNib {
    [self setTitle:@""];
    [self setTitlebarAppearsTransparent:YES];
    needToMoveCloseButton = YES;
    needToMoveMiniaturizeButton = YES;
    needToMoveZoomButton = YES;
}

- (void)layoutIfNeeded {
    [super layoutIfNeeded];
    [self moveButtonOfType:NSWindowCloseButton];
    [self moveButtonOfType:NSWindowMiniaturizeButton];
    [self moveButtonOfType:NSWindowZoomButton];
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
