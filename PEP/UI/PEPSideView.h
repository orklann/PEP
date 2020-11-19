//
//  PEPSideView.h
//  PEP
//
//  Created by Aaron Elkins on 11/17/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

#define kSideViewWidth 280

@interface PEPSideView : NSView {
    NSPopUpButton *familyList;
    NSTextField *fontLabel;
}

- (void)initAllViews;
- (void)layoutViews;
- (void)layoutFontView;
@end

NS_ASSUME_NONNULL_END
