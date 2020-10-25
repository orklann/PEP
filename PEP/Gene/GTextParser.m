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

- (GGlyph*)nextGlyph {
    glyphPos += 1;
    return [self currentGlyph];
}

- (GGlyph*)currentGlyph {
    if (glyphPos < [glyphs count]) {
        return [glyphs objectAtIndex:glyphPos];
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
    glyphs = sortGlyphsInReadOrder(glyphs);
    NSMutableString *s = [NSMutableString string];
    int i;
    for (i = 0; i < [glyphs count]; i++) {
        GGlyph *g = [glyphs objectAtIndex:i];
        [s appendString:[g content]];
    }
    printf("====\n");
    printf("%s\n", [s UTF8String]);
}

- (void)makeIndexInfoForGlyphs {
    NSArray *glyphs = [self glyphs];
    int i;
    for (i = 0; i < [glyphs count]; i++) {
        GGlyph *g = [glyphs objectAtIndex:i];
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
            [words addObject:currentWord];
            currentWord = [GWord create];
            [currentWord addGlyph:nextGlyph];
            [words addObject:currentWord];
            currentWord = [GWord create];
        } else {
            [currentWord addGlyph:nextGlyph];
        }
        nextGlyph = [self nextGlyph];
    }
    
    if ([[currentWord glyphs] count] > 0) {
        [words addObject:currentWord];
    }
    
    return words;
}

- (NSMutableArray*)makeLines {
    [self makeWords];
    
    lines = [NSMutableArray array];
    
    GLine *line = [GLine create];
    GWord *currentWord = [words firstObject];
    [line addWord:currentWord];
    int i;
    for (i = 1; i < [words count]; i++) {
        GWord *nextWord = [words objectAtIndex:i];
        if (separateWords(currentWord, nextWord)) {
            [line addWord:nextWord];
            currentWord = nextWord;
        } else if (!separateWords(currentWord, nextWord)) {
            [lines addObject:line];
            currentWord = nextWord;
            line = [GLine create];
            [line addWord:currentWord];
        }
    }
    
    // Add last line if it contains words
    if ([[line words] count] > 0) {
        [lines addObject:line];
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
