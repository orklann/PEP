//
//  GGraphicsState.h
//  PEP
//
//  Created by Aaron Elkins on 9/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GGraphicsState : NSObject {
    CGAffineTransform ctm;
}
+ (id)create;
- (void)setCTM:(CGAffineTransform)tf;
- (CGAffineTransform)ctm;
@end

NS_ASSUME_NONNULL_END
