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
    CGAffineTransform textMatrix;
    CGFloat charSpace;
    CGFloat wordSpace;
    CGFloat scale;
    CGFloat leading;
    CGFloat render;
    CGFloat rise;
}

+ (id)create;
- (void)initTextState;
- (void)setFontName:(NSString*)name;
- (NSString*)fontName;
- (void)setFontSize:(CGFloat)size;
- (CGFloat)fontSize;
- (void)setTextMatrix:(CGAffineTransform)tm;
- (CGAffineTransform)textMatrix;
- (void)setCharSpace:(CGFloat)cs;
- (CGFloat)charSpace;
- (void)setWordSpace:(CGFloat)ws;
- (CGFloat)wordSpace;
- (void)setScale:(CGFloat)s;
- (CGFloat)scale;
- (void)setLeading:(CGFloat)l;
- (CGFloat)leading;
- (void)setRender:(CGFloat)r;
- (CGFloat)render;
- (void)setRise:(CGFloat)r;
- (CGFloat)rise;

@end

NS_ASSUME_NONNULL_END
