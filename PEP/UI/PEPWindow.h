//
//  PEPWindow.h
//  PEP
//
//  Created by Aaron Elkins on 11/14/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PEPTopView.h"
NS_ASSUME_NONNULL_BEGIN

#define kMoveButtonDelta 8.0

@interface PEPWindow : NSWindow {
    BOOL needToMoveCloseButton;
    BOOL needToMoveMiniaturizeButton;
    BOOL needToMoveZoomButton;
    PEPTopView *topView;
}

- (void)needToMoveButtons;
- (void)layoutViews;
@end

NS_ASSUME_NONNULL_END
