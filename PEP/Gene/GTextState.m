//
//  GTextState.m
//  PEP
//
//  Created by Aaron Elkins on 9/24/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GTextState.h"

@implementation GTextState
+ (id)create {
    GTextState *ts = [[GTextState alloc] init];
    [ts initTextState];
    return ts;
}

- (void)initTextState {
    charSpace = 0;
    wordSpace = 0;
    scale = 100; // Notice: not 0
    leading = 0;
    render = 0;
    rise = 0;
    fontSize = 1.0;
    textMatrix = CGAffineTransformIdentity;
    lineMatrix = CGAffineTransformIdentity;
}

- (void)setFontName:(NSString*)name {
    fontName = name;
}

- (NSString*)fontName {
    return fontName;
}

- (void)setFontSize:(CGFloat)size {
    fontSize = size;
}

- (CGFloat)fontSize {
    return fontSize;
}

- (void)setTextMatrix:(CGAffineTransform)tm {
    textMatrix = tm;
}

- (CGAffineTransform)textMatrix {
    return textMatrix;
}

- (void)setLineMatrix:(CGAffineTransform)lm {
    lineMatrix = lm;
}

- (CGAffineTransform)lineMatrix {
    return lineMatrix;
}

- (void)setCharSpace:(CGFloat)cs {
    charSpace = cs;
}

- (CGFloat)charSpace {
    return charSpace;
}

- (void)setWordSpace:(CGFloat)ws {
    wordSpace = ws;
}

- (CGFloat)wordSpace {
    return wordSpace;
}

- (void)setScale:(CGFloat)s {
    scale = s;
}

- (CGFloat)scale {
    return scale;
}

- (void)setLeading:(CGFloat)l {
    leading = l;
}

- (CGFloat)leading {
    return leading;
}

- (void)setRender:(CGFloat)r {
    render = r;
}

- (CGFloat)render {
    return render;
}

- (void)setRise:(CGFloat)r {
    rise = r;
}

- (CGFloat)rise {
    return rise;
}

- (GTextState*)clone {
    GTextState *newTextState = [GTextState create];
    [newTextState setFontName:fontName];
    [newTextState setFontSize:fontSize];
    [newTextState setTextMatrix:textMatrix];
    [newTextState setLineMatrix:lineMatrix];
    [newTextState setCharSpace:charSpace];
    [newTextState setWordSpace:wordSpace];
    [newTextState setScale:scale];
    [newTextState setLeading:leading];
    [newTextState setRender:render];
    [newTextState setRise:rise];
    return newTextState;
}
@end
