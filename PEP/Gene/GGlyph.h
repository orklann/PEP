//
//  GGlyph.h
//  PEP
//
//  Created by Aaron Elkins on 10/5/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class GPage;
@class GFontEncoding;

@interface GGlyph : NSObject {
    NSRect frame;
    NSString *content;
    NSPoint point;
    CGFloat height;
}

@property (readwrite) GPage *page;
@property (readwrite) NSFont *font;
@property (readwrite) CGGlyph glyph;
@property (readwrite) CGFloat delta;
@property (readwrite) CGFloat wordSpace;
@property (readwrite) CGFloat characterSpace;
@property (readwrite) CGFloat rise;
@property (readwrite) CGFloat fs;
@property (readwrite) int indexOfBlock;
@property (readwrite) CGFloat width;
@property (readwrite) CGFloat widthInGlyphSpace;
@property (readwrite) NSRect frameInGlyphSpace;
@property (readwrite) CGAffineTransform ctm;
@property (readwrite) CGAffineTransform textMatrix;
@property (readwrite) NSString *fontName;
@property (readwrite) CGFloat fontSize;
@property (readwrite) int lineIndex;
@property (readwrite) char *_Nullable* _Nullable encoding;
@property (readwrite) GFontEncoding* fontEncoding;
@property (readwrite) NSColor *textColor;

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

// Update glyph width (a.k.a advance), frame (in user space and in glyph space)
- (void)updateGlyphWidth;
- (void)updateGlyphFrame;
- (void)updateGlyphFrameInGlyphSpace;
@end

NS_ASSUME_NONNULL_END
