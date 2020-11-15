//
//  PEPTab.h
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEPTabView;

NS_ASSUME_NONNULL_BEGIN
#define kTabRadius 5

@interface PEPTab : NSObject {
    NSString *title;
}

@property (readwrite) PEPTabView *tabView;

+ (id)create;
- (void)setTitle:(NSString*)t;
- (void)draw:(CGContextRef)context;
@end

NS_ASSUME_NONNULL_END
