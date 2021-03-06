//
//  GTextState.h
//  PEP
//
//  Created by Aaron Elkins on 9/24/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GFontEncoding.h"

NS_ASSUME_NONNULL_BEGIN

@interface GTextState : NSObject {
    NSString *fontName;
    CGFloat fontSize;
    CGAffineTransform textMatrix;
    CGAffineTransform lineMatrix;
    CGFloat charSpace;
    CGFloat wordSpace;
    CGFloat scale;
    CGFloat leading;
    CGFloat render;
    CGFloat rise;
}

// Extra text states which are not in the spec,
// but for the design of PEP
@property (readwrite) char * _Nonnull * _Nonnull encoding;
@property (readwrite) GFontEncoding *fontEncoding;

+ (id)create;
- (void)initTextState;
- (void)setFontName:(NSString*)name;
- (NSString*)fontName;
- (void)setFontSize:(CGFloat)size;
- (CGFloat)fontSize;
- (void)setTextMatrix:(CGAffineTransform)tm;
- (CGAffineTransform)textMatrix;
- (void)setLineMatrix:(CGAffineTransform)lm;
- (CGAffineTransform)lineMatrix;
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
- (GTextState*)clone;
@end

NS_ASSUME_NONNULL_END
