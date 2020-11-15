//
//  PEPTab.h
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PEPTab : NSObject {
    NSString *title;
    NSRect rect;
}

- (void)setTitle:(NSString*)t;
- (void)setRect:(NSRect)r;
@end

NS_ASSUME_NONNULL_END
