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
@class GTextBlock;
@class GTJText;

NS_ASSUME_NONNULL_BEGIN
// Print NSData in character strings
void printData(NSData *data);

// Print NSString as hex char code
void printNSStringHex(NSString *s);

// Compare method for sorting glyphs in read order
int compareGlyphs(GGlyph *a, GGlyph *b);

// Compare method for sorting GTJTexts in read order
int compareTJTexts(GTJText *a, GTJText *b);

// Check if two glyphs are almost at the same x-coordinate, that's in the same line
BOOL glyphsInTheSameLine(GGlyph *a, GGlyph *b);

NSMutableArray *sortGlyphsInReadOrder(NSMutableArray *glyphs);

// quick sort not used yet
// TODO: Use quick sort to improve performance
NSMutableArray* quicksortGlyphs(NSMutableArray *array);

// Check if two words form a line
BOOL separateWords(GWord* a, GWord*b);

// Distance between to points;
CGFloat distance(NSPoint a, NSPoint b);

// Check if two lines form a text block
BOOL separateLines(GLine *a, GLine *b);

// Translate point to new origin
// Here we assume old origin is at (0, 0) 
NSPoint translatePoint(NSPoint p, NSPoint newOrigin);

// NSSet to NSString
NSString *setToString(NSSet* set);

// Print all table tags for a CGFont
void printTableTagsForCGFont(CGFontRef font);

// Build CGFont into NSData which can be saved as ttf, otf font
NSData* fontDataForCGFont(CGFontRef cgFont);

// Sort GBinaryData array by comparing objectNumber of GBinaryData
NSMutableArray *sortedGBinaryDataArray(NSMutableArray *array);

// Grouping GBinaryData array for build new xref table
NSMutableArray *groupingGBinaryDataArray(NSMutableArray *array);

// Padding total 10 zero for object number in XRef entry
NSString* paddingTenZero(int offset);

// Padding total 5 zero for generation number in XRef entry
NSString* paddingFiveZero(int generationNumber);

// Build XRef entry, example: "0000012345 00000 n\r\n"
NSString *buildXRefEntry(int offset, int generationNumber, NSString *state);
NS_ASSUME_NONNULL_END

// Better log for GTextBlock
void prettyLogForTextBlock(GTextBlock* _Nullable textBlock);

// Better log for GWords array
void prettyLogForWords(NSArray * _Nullable words);

// Better log char codes for GWords array
void prettyLogCharCodesForWords(NSArray * _Nullable words);

// Check for white space
BOOL isWhiteSpaceChar(char c);

// Check for white space glyph
BOOL isWhiteSpaceGlyph(GGlyph * _Nullable glyph);

// Check for Enter/Return glpyh
BOOL isReturnChar(char c);
BOOL isReturnGlyph(GGlyph * _Nullable glyph);

// Log glyphs index in GTextEditor's editingGlyphs array
void logGlyphsIndex(NSArray * _Nullable glyphs);
// Log glyphs content in GTextEditor's glyphs
void logGlyphsContent(NSArray * _Nullable glyphs);

void printCGAffineTransform(CGAffineTransform mt);

// Get sign of a CGFloat
int signOfCGFloat(CGFloat v);

// Get object number and generation number from ref string
// Ref string is in the format "1-0", "12-0", etc
int getObjectNumber(NSString * _Nullable ref);
int getGenerationNumber(NSString * _Nullable ref);
