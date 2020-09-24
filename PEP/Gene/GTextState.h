//
//  GTextState.h
//  PEP
//
//  Created by Aaron Elkins on 9/24/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GTextState : NSObject {
    NSString *fontName;
    CGFloat fontSize;
}

+ (id)create;
- (void)setFontName:(NSString*)name;
- (NSString*)fontName;
- (void)setFontSize:(CGFloat)size;
- (CGFloat)fontSize;
@end

NS_ASSUME_NONNULL_END
