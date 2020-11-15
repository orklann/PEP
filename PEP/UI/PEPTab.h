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
    BOOL active;
}

@property (readwrite) PEPTabView *tabView;
@property (readwrite) id delegate;

+ (id)create;
- (void)setTitle:(NSString*)t;
- (NSString*)title;
- (void)setActive:(BOOL)a;
- (void)draw:(CGContextRef)context;
@end
NS_ASSUME_NONNULL_END
