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
@class GLine;

NS_ASSUME_NONNULL_BEGIN
// Print NSData in character strings
void printData(NSData *data);

// Get glyph width
CGFloat getGlyphAdvanceForFont(NSString *ch, NSFont *font);

// Get glyph bounding box, in user space.
NSRect getGlyphBoundingBox(NSString *ch, NSFont *font, CGAffineTransform tm);

// Compare method for sorting glyphs in read order
int compareGlyphs(GGlyph *a, GGlyph *b);

NSMutableArray *sortGlyphsInReadOrder(NSMutableArray *glyphs);

// quick sort not used yet
// TODO: Use quick sort to improve performance
void quicksortGlyphs(NSMutableArray *array, int l, int r);

// Check if two glyphs separate two characters
BOOL separateCharacters(GGlyph *a, GGlyph *b);

// Check if two words form a line
BOOL separateWords(GWord* a, GWord*b);

// Distance between to points;
CGFloat distance(NSPoint a, NSPoint b);

// Check if two lines form a text block
BOOL separateLines(GLine *a, GLine *b);

// Translate point to new origin
// Here we assume old origin is at (0, 0) 
NSPoint translatePoint(NSPoint p, NSPoint newOrigin);
NS_ASSUME_NONNULL_END
