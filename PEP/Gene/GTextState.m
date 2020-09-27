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
    return ts;
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
@end
