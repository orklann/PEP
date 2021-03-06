//
//  GTextParser.h
//  PEP
//
//  Created by Aaron Elkins on 10/5/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class GWord;
@class GGlyph;
@class GTextBlock;
@class GPage;

@interface GTextParser : NSObject {
    NSMutableArray *glyphs;
    NSMutableArray *readOrderGlyphs;
    NSMutableArray *words;
    NSMutableArray *lines;
    NSMutableArray *textBlocks;
    
    /*
     * Use GTJText, which contans all glyphs of one Tj or TJ commands,
     * with it, we can speed up to make read order glyphs in GTextParser,
     * so that, we have no lag while highlight current text block in mouse
     * cursor.
     */
    NSMutableArray *tjTexts;
    
    unsigned int glyphPos;
    unsigned int wordPos;
    BOOL cached;
    BOOL useTJTexts;
}

+ (id)create;
- (void)setUseTJTexts:(BOOL)flag;
- (void)setCached:(BOOL)c;
- (NSMutableArray*)glyphs;
- (void)setGlyphs:(NSMutableArray*)gs;
- (NSMutableArray*)tjTexts;
- (void)setTJTexts:(NSMutableArray*)texts;
- (NSMutableArray*)readOrderGlyphs;
- (GGlyph*)peekPrevGlyph;
- (GGlyph*)nextGlyph;
- (GGlyph*)peekNextGlyph;
- (GGlyph*)currentGlyph;
- (GWord*)nextWord;
- (GWord*)currentWord;
- (NSMutableArray*)words;
- (NSMutableArray*)lines;
- (void)makeReadOrderGlyphs;
- (NSMutableArray*)makeWords;
- (NSMutableArray*)makeLines;
- (NSMutableArray*)makeTextBlocks;
- (GTextBlock *)mergeLinesToTextblock;
- (NSMutableArray*)textBlocks;
@end

NS_ASSUME_NONNULL_END
