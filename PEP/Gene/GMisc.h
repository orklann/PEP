//
//  GMisc.h
//  PEP
//
//  Created by Aaron Elkins on 9/18/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGlyph;
@class GWord;

NS_ASSUME_NONNULL_BEGIN
// Print NSData in character strings
void printData(NSData *data);

// Get glyph width
CGFloat getGlyphAdvanceForFont(NSString *ch, NSFont *font);
NSRect getGlyphBoundingBox(NSString *ch, NSFont *font, CGAffineTransform tm, CGFloat advance);

// Compare method for sorting glyphs in read order
int compareGlyphs(GGlyph *a, GGlyph *b);

void quicksortGlyphs(NSMutableArray *array, int l, int r);

// Check if two glyphs separate two characters
BOOL separateCharacters(GGlyph *a, GGlyph *b);

// Check if two words form a line
BOOL separateWords(GWord* a, GWord*b);
NS_ASSUME_NONNULL_END
