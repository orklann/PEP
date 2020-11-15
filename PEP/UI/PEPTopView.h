//
//  PEPTopView.h
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PEPTabView.h"
#import "PEPToolbarView.h"

NS_ASSUME_NONNULL_BEGIN

#define kTopViewHeight 80

@interface PEPTopView : NSView

- (void)layoutViews;
@end

NS_ASSUME_NONNULL_END
