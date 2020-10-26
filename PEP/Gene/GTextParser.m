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

@implementation GTextParser
+ (id)create {
    GTextParser *tp = [[GTextParser alloc] init];
    NSMutableArray *gs = [NSMutableArray array];
    NSMutableArray *ws = [NSMutableArray array];
    NSMutableArray *ls = [NSMutableArray array];
    [tp setGlyphs:gs];
    [tp setWords:ws];
    [tp setLines:ls];
    return tp;
}

- (void)setGlyphs:(NSMutableArray*)gs {
    glyphs = gs;
}

- (NSMutableArray*)glyphs {
    return glyphs;
}

- (NSMutableArray*)readOrderGlyphs {
    return readOrderGlyphs;
}

- (GGlyph*)nextGlyph {
    glyphPos += 1;
    return [self currentGlyph];
}

- (GGlyph*)currentGlyph {
    if (glyphPos < [readOrderGlyphs count]) {
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
    readOrderGlyphs = sortGlyphsInReadOrder(glyphs);
    NSMutableString *s = [NSMutableString string];
    int i;
    for (i = 0; i < [readOrderGlyphs count]; i++) {
        GGlyph *g = [readOrderGlyphs objectAtIndex:i];
        [s appendString:[g content]];
    }
    printf("====Read Order Glyphs====\n");
    printf("%s\n", [s UTF8String]);
    
    s = [NSMutableString string];
    for (i = 0; i < [glyphs count]; i++) {
        GGlyph *g = [glyphs objectAtIndex:i];
        [s appendString:[g content]];
    }
    printf("====Original Glyphs======\n");
    printf("%s\n", [s UTF8String]);
    printf("====@@@@@@@@@@@@@@@@=====\n");
}

- (void)makeIndexInfoForGlyphs {
    NSArray *gs = readOrderGlyphs;
    int i;
    for (i = 0; i < [gs count]; i++) {
        GGlyph *g = [gs objectAtIndex:i];
        g.indexOfPageGlyphs = i;
    }
}

// Note: This method does not tested well
// Just check back later
- (NSMutableArray*)makeWords {
    [self makeReadOrderGlyphs];
    [self makeIndexInfoForGlyphs];
    words = [NSMutableArray array];
    
    glyphPos = 0;
    
    GGlyph *currentGlyph = [self currentGlyph];
    GWord *currentWord = [GWord create];
    [currentWord addGlyph:currentGlyph];
    GGlyph *nextGlyph = [self nextGlyph];
    while(nextGlyph != nil) {
        if (isWhiteSpaceGlyph(nextGlyph)) {
            // Add previous word
            [words addObject:currentWord];
            
            // Handle edge case: where more than two white spaces stick
            // together. We add each white space as a single word until we
            // reach a none white space
            //nextGlyph = [self nextGlyph];
            while (isWhiteSpaceGlyph(nextGlyph)) {
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
    
    return words;
}

- (NSMutableArray*)makeLines {
    [self makeWords];
    
    lines = [NSMutableArray array];
    
    wordPos = 0;
    
    GLine *currentLine = [GLine create];
    GWord *currentWord = [self currentWord];
    [currentLine addWord:currentWord];
    GWord *nextWord = [self nextWord];
    while(nextWord != nil) {
        if (separateWords(currentWord, nextWord)) {
            [currentLine addWord:nextWord];
            currentWord = nextWord;
        } else { // In this case, line breaks happens
            [lines addObject:currentLine];
            currentWord = nextWord;
            currentLine = [GLine create];
            [currentLine addWord:currentWord];
        }
        nextWord = [self nextWord];
    }
    
    if ([[currentLine words] count] > 0) {
        [lines addObject:currentLine];
    }
    
    return lines;
}

- (NSMutableArray*)makeTextBlocks {
    [self makeLines];
    textBlocks = [NSMutableArray array];
    
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
@end
