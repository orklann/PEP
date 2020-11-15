//
//  PEPTabDelegate.h
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PEPTab;

@protocol PEPTabDelegate <NSObject>
@optional
- (void)tabDidActive:(PEPTab*)tab;
@end

NS_ASSUME_NONNULL_END
