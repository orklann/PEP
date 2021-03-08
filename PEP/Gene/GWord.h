//
//  GWord.h
//  PEP
//
//  Created by Aaron Elkins on 10/6/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGlyph;
NS_ASSUME_NONNULL_BEGIN

/*
 * Indicate that we have no native distance between words, for example the last word in previous line
 * and first word in current line, we can add our own distance while doing word wrapping.
 */
#define kNoWordDistance -1

@interface GWord : NSObject {
    NSMutableArray *glyphs;
    NSRect frame;
}

/*
 * Word distance between this word and previous word in text space, this property is only used in word
 * wrapping in text parser
 */
@property (readwrite) CGFloat wordDistance;

+ (id)create;
- (void)setGlyphs:(NSMutableArray *)gs;
- (void)setFrame:(NSRect)f;
- (NSRect)frame;
- (NSMutableArray*)glyphs;
- (void)addGlyph:(GGlyph*)g;
- (NSString*)wordString;
- (CGFloat)getWordWidth;
@end

NS_ASSUME_NONNULL_END
