//
//  PEPSideView.h
//  PEP
//
//  Created by Aaron Elkins on 11/17/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GTextEditorDelegate.h"
NS_ASSUME_NONNULL_BEGIN

#define kSideViewWidth 280

@interface PEPSideView : NSView <NSMenuDelegate, GTextEditorDelegate> {
    NSPopUpButton *familyList;
    NSPopUpButton *styleList;
    NSComboBox *fontSizeList;
    NSTextField *fontLabel;
    NSTextField *styleLabel;
    NSMutableDictionary *familyDictionary;
    NSArray *fontList;
    NSArray *fontfamilies;
}

- (void)initAllViews;
- (void)layoutViews;
- (void)layoutFontView;
- (NSString*)selectedFamily;
- (NSString*)selectedStyle;
@end

NS_ASSUME_NONNULL_END
