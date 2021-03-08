//
//  GTextParser.m
//  PEP
//
//  Created by Aaron Elkins on 10/5/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GTextParser.h"
#import "GMisc.h"
#import "GGlyph.h"
#import "GWord.h"
#import "GLine.h"
#import "GTextBlock.h"
#import "GConstants.h"
#import "GTJText.h"

@implementation GTextParser
+ (id)create {
    GTextParser *tp = [[GTextParser alloc] init];
    NSMutableArray *gs = [NSMutableArray array];
    NSMutableArray *texts = [NSMutableArray array];
    NSMutableArray *ws = [NSMutableArray array];
    NSMutableArray *ls = [NSMutableArray array];
    [tp setGlyphs:gs];
    [tp setTJTexts:texts];
    [tp setWords:ws];
    [tp setLines:ls];
    [tp setCached:NO];
    /* Default we will make read order glyphs by using tjTexts array
     * Only not to use tjTexts while in GPage's buildPageContent, in there
     * We directly call makeReadOrderGlyphs
     */
    [tp setUseTJTexts:YES];
    return tp;
}

- (void)setGlyphs:(NSMutableArray*)gs {
    glyphs = gs;
}

- (NSMutableArray*)tjTexts {
    return tjTexts;
}

- (void)setTJTexts:(NSMutableArray*)texts {
    tjTexts = texts;
}

- (void)setUseTJTexts:(BOOL)flag {
    useTJTexts = flag;
}

- (void)setCached:(BOOL)c {
    cached = c;
}

- (NSMutableArray*)glyphs {
    return glyphs;
}

- (NSMutableArray*)readOrderGlyphs {
    return readOrderGlyphs;
}

- (GGlyph*)peekPrevGlyph {
    int pos = glyphPos - 1;
    if (pos >= 0 && pos < [readOrderGlyphs count]) {
        return [readOrderGlyphs objectAtIndex:pos];
    }
    return nil;
}

- (GGlyph*)nextGlyph {
    glyphPos += 1;
    return [self currentGlyph];
}

- (GGlyph*)peekNextGlyph {
    int pos = glyphPos + 1;
    if (pos >= 0 && pos < [readOrderGlyphs count]) {
        return [readOrderGlyphs objectAtIndex:pos];
    }
    return nil;
}

- (GGlyph*)currentGlyph {
    if (glyphPos >= 0 && glyphPos < [readOrderGlyphs count]) {
        return [readOrderGlyphs objectAtIndex:glyphPos];
    }
    return nil;
}

- (GWord*)nextWord {
    wordPos += 1;
    return [self currentWord];
}

- (GWord*)currentWord {
    if (wordPos < [words count]) {
        return [words objectAtIndex:wordPos];
    }
    return nil;
}

- (void)setWords:(NSMutableArray*)ws {
    words = ws;
}

- (NSMutableArray*)words {
    return words;
}

- (void)setLines:(NSMutableArray*)ls {
    lines = ls;
}

- (NSMutableArray*)lines {
    return lines;
}

- (void)makeReadOrderGlyphs {
    if (cached) return;
    readOrderGlyphs = sortGlyphsInReadOrder(glyphs);
    cached = YES;
}

- (void)makeReadOrderGlyphsWithTJTexts {
    if (cached) return ;
    tjTexts = quicksortGTJTexts(tjTexts);
    readOrderGlyphs = [NSMutableArray array];
    for (GTJText *text in tjTexts) {
        [readOrderGlyphs addObjectsFromArray:[text glyphs]];
    }
    cached = YES;
}

/*
 * White spaces break words, and words break by geometry too
 * See isGlyphBreakWord:
 */
- (NSMutableArray*)makeWords{
    if (cached) return words;
    
    if (useTJTexts) {
        [self makeReadOrderGlyphsWithTJTexts];
    } else {
        [self makeReadOrderGlyphs];
    }
    
    cached = YES;
    
    words = [NSMutableArray array];
    
    if ([readOrderGlyphs count] <= 0) {
        return words;
    }
    
    glyphPos = 0;

    GWord *currentWord = [GWord create];
    GGlyph *nextGlyph = [self currentGlyph];
    while(nextGlyph != nil) {
        if ([self isGlyphBreakWord:nextGlyph]) { // Geometry word break
            // Add previous word
            if ([[currentWord glyphs] count] > 0)  {
                [words addObject:currentWord];
            }
            currentWord = [GWord create];
            [currentWord addGlyph:nextGlyph];
            nextGlyph = [self nextGlyph];
        } else if (isWhiteSpaceGlyph(nextGlyph)) {
            // Add previous word
            if ([[currentWord glyphs] count] > 0)  {
                [words addObject:currentWord];
            }
            
            // Handle edge case: where more than two white spaces stick
            // together. We add each white space as a single word until we
            // reach a none white space.
            // nextGlyph == nil means last glyph is a white space, so we stop while loop in this case
            while (isWhiteSpaceGlyph(nextGlyph) && nextGlyph != nil) {
                currentWord = [GWord create];
                [currentWord addGlyph:nextGlyph];
                [words addObject:currentWord];
                nextGlyph = [self nextGlyph];
            }
            
            currentWord = [GWord create];
        } else {
            [currentWord addGlyph:nextGlyph];
            nextGlyph = [self nextGlyph];
        }
    }
    
    if ([[currentWord glyphs] count] > 0) {
        [words addObject:currentWord];
    }
    
    //prettyLogForWords(words);
    return words;
}

- (NSMutableArray*)makeLines {
    if (cached) return lines;
    [self makeWords];
    cached = YES;
    lines = [NSMutableArray array];
    
    if ([words count] <= 0) {
        return lines;
    }
    
    wordPos = 0;
    
    /*
     * About word distance:
     * 1. Word distance in first word of the text block is 0.
     * 2. Word distance in first word of a line is kNoWordDisctance
     * 3. Word distance is applied by CTM for the first glyph
     */
    
    GLine *currentLine = [GLine create];
    GWord *currentWord = [self currentWord];
    [currentWord setWordDistance:0];
    [currentLine addWord:currentWord];
    GWord *nextWord = [self nextWord];
    CGFloat wordDistance;
    while(nextWord != nil) {
        if (separateWords(currentWord, nextWord)) {
            [currentLine addWord:nextWord];
            wordDistance = getWordDistance(currentWord, nextWord);
            [nextWord setWordDistance:wordDistance];
            currentWord = nextWord;
        } else { // In this case, line breaks happens
            [lines addObject:currentLine];
            currentWord = nextWord;
            currentLine = [GLine create];
            [currentLine addWord:currentWord];
            [currentWord setWordDistance:kNoWordDistance];
        }
        nextWord = [self nextWord];
    }
    
    if ([[currentLine words] count] > 0) {
        [lines addObject:currentLine];
    }
    return lines;
}

// From left to right, and colum by colum, used for multiple colum text layout
- (void)makeReadOrderLines {
    CGFloat distanceThrehold = kLinesPostionThresold; // Left position of two lines delta threshold
    NSMutableArray *initialLines = [NSMutableArray arrayWithArray:lines];
    NSMutableArray *result = [NSMutableArray array];
    NSMutableArray *tmp = [NSMutableArray array];
    while ([initialLines count] > 0) {
        GLine *currentLine = [initialLines firstObject];
        NSRect f1 = [currentLine frame];
        [result addObject:currentLine];
        [tmp addObject:currentLine];
        for (int i = 1; i < [initialLines count]; i++) {
            GLine *nextLine = [initialLines objectAtIndex:i];
            NSRect f2 = [nextLine frame];
            CGFloat minX = NSMinX(f1);
            CGFloat maxX = NSMaxX(f1);
            if (fabs(f2.origin.x - minX) <= distanceThrehold && f2.origin.x <= maxX) {
                [result addObject:nextLine];
                [tmp addObject:nextLine];
            }
        }
        [initialLines removeObjectsInArray:tmp];
    }
    // Update lines
    lines = result;
}

- (NSMutableArray*)makeTextBlocks {
    if (cached) return textBlocks;
    [self makeLines];
    cached = YES;
    textBlocks = [NSMutableArray array];
    
    if ([lines count] <= 0) {
        return textBlocks;
    }
    
    // Make read order lines first
    [self makeReadOrderLines];
    
    GTextBlock *textBlock = [GTextBlock create];
    GLine *currentLine = [lines firstObject];
    int i;
    [textBlock addLine:currentLine];
    for (i = 1; i < [lines count]; i++) {
        GLine *nextLine = [lines objectAtIndex:i];
        if (separateLines(currentLine, nextLine)) {
            [textBlock addLine:nextLine];
            currentLine = nextLine;
        } else {
            [textBlocks addObject:textBlock];
            currentLine = nextLine;
            textBlock = [GTextBlock create];
            [textBlock addLine:currentLine];
        }
    }
    
    // Add last text block if it contains any line
    if ([[textBlock lines] count] > 0) {
        [textBlocks addObject:textBlock];
    }
    return textBlocks;
}

- (GTextBlock *)mergeLinesToTextblock {
    [self makeLines];
    if ([lines count] <= 0)  {
        return nil;
    }
    GTextBlock *textBlock = [GTextBlock create];
    for (GLine *l in lines) {
        [textBlock addLine:l];
    }
    return textBlock;
}

- (BOOL)isGlyphBreakWord:(GGlyph*)a{
    // a is current glyph, we also need previous glyph
    GGlyph *prevGlyph = [self peekPrevGlyph];
    
    // TODO: Add a [GTextParser onlyWhiteSpaceCanBreakWord] as an option to skip this check
    if (prevGlyph != nil && a != nil && !glyphsInTheSameLine(prevGlyph, a)) {
        return YES;
    }
    
    // Check if next glyph a is farther away from prev glyph, the threshold distance is 1/20 * width
    // of the prev glyph. threshold = 1/20 * (width of prev glyph)
    
    if (prevGlyph != nil && a != nil) {
        CGRect f1 = [prevGlyph frame];
        CGRect f2 = [a frame];
        CGFloat maxX = NSMaxX(f1);
        CGFloat distance = fabs(f2.origin.x - maxX);
        CGFloat threshold = f1.size.width / 4;  // threshold to be prev glyph width / 4
        CGFloat yThreshold = 2.0;               // y-distance threshold to be 2px
        if ((distance >= threshold && f2.origin.x >= maxX) || /*
                                                               * after prev glyph and distance
                                                               * bigger than threshold
                                                               */
            fabs(f2.origin.y - f1.origin.y) >= yThreshold   // or two glyphs are not in the same line
            ) {
            return YES;
        }
    }
    
    return NO;
}

- (void)logGlyphs {
    NSMutableString *s = [NSMutableString string];
    int i;
    for (i = 0; i < [readOrderGlyphs count]; i++) {
        GGlyph *g = [readOrderGlyphs objectAtIndex:i];
        [s appendString:[g content]];
    }
    printf("Debug:====Read Order Glyphs====\n");
    printf("Debug:%s\n", [s UTF8String]);
    
    s = [NSMutableString string];
    for (i = 0; i < [glyphs count]; i++) {
        GGlyph *g = [glyphs objectAtIndex:i];
        [s appendString:[g content]];
    }
    printf("Debug:====Original Glyphs======\n");
    printf("Debug:%s\n", [s UTF8String]);
    printf("Debug:====@@@@@@@@@@@@@@@@=====\n");
}
@end
