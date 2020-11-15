//
//  PEPTabview.h
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PEPTab.h"

NS_ASSUME_NONNULL_BEGIN

#define kTabWidth 90
#define kTabHeight 34

@interface PEPTabView : NSView {
    NSMutableArray *tabs;
}

- (void)initTabs;
- (NSRect)getRectForTab:(PEPTab*)tab;
@end

NS_ASSUME_NONNULL_END
