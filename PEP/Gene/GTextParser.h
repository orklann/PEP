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

@interface GTextParser : NSObject {
    NSMutableArray *glyphs;
    NSMutableArray *readOrderGlyphs;
    NSMutableArray *words;
    NSMutableArray *lines;
    NSMutableArray *textBlocks;
    unsigned int glyphPos;
    unsigned int wordPos;
}
+ (id)create;
- (NSMutableArray*)glyphs;
- (NSMutableArray*)readOrderGlyphs;
- (GGlyph*)nextGlyph;
- (GGlyph*)currentGlyph;
- (GWord*)nextWord;
- (GWord*)currentWord;
- (NSMutableArray*)words;
- (NSMutableArray*)lines;
- (void)makeReadOrderGlyphs;
- (NSMutableArray*)makeWords;
- (NSMutableArray*)makeLines;
- (NSMutableArray*)makeTextBlocks;
@end

NS_ASSUME_NONNULL_END
