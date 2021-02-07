//
//  GGlyph.h
//  PEP
//
//  Created by Aaron Elkins on 10/5/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GGlyph : NSObject {
    NSRect frame;
    NSString *content;
    NSPoint point;
    CGFloat height;
}

@property (readwrite) NSFont *font;
@property (readwrite) CGGlyph glyph;
@property (readwrite) int delta;
@property (readwrite) CGFloat wordSpace;
@property (readwrite) CGFloat characterSpace;
@property (readwrite) int indexOfBlock;
@property (readwrite) CGFloat width;
@property (readwrite) NSRect frameInGlyphSpace;
@property (readwrite) CGAffineTransform ctm;
@property (readwrite) CGAffineTransform textMatrix;
@property (readwrite) NSString *fontName;
@property (readwrite) CGFloat fontSize;
@property (readwrite) int lineIndex;

+ (id)create;
- (void)setFrame:(NSRect)f;
- (NSRect)frame;
- (void)setHeight:(CGFloat)h;
- (CGFloat)height;
- (void)setPoint:(NSPoint)p;
- (NSPoint)point;
- (void)setContent:(NSString*)s;
- (NSString*)content;
- (NSString*)literalString;
- (NSString*)complieToOperators;
- (NSArray*)compileToCommands;
@end

NS_ASSUME_NONNULL_END
