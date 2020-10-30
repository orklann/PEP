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

- (GGlyph*)peekNextGlyph {
    int pos = glyphPos + 1;
    if (pos >= 0 && pos < [readOrderGlyphs count]) {
        return [readOrderGlyphs objectAtIndex:pos];
    }
    return nil;
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


/*
 * Only white space breaks words.
 * Old code which check if two character break words in geometry info.
 * See: https://gist.github.com/orklann/5a7a4ae666368bd23406801e8951c6ad
 */
- (NSMutableArray*)makeWords{
    [self makeReadOrderGlyphs];
    
    words = [NSMutableArray array];
    
    if ([readOrderGlyphs count] <= 0) {
        return words;
    }
    
    glyphPos = 0;
    
    GWord *currentWord = [GWord create];
    GGlyph *nextGlyph = [self currentGlyph];
    while(nextGlyph != nil) {
        if (isWhiteSpaceGlyph(nextGlyph)) {
            // Add previous word
            [words addObject:currentWord];
            
            // Handle edge case: where more than two white spaces stick
            // together. We add each white space as a single word until we
            // reach a none white space
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
    
    //prettyLogForWords(words);
    
    return words;
}

- (NSMutableArray*)makeLines {
    [self makeWords];
    
    lines = [NSMutableArray array];
    
    if ([words count] <= 0) {
        return lines;
    }
    
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
    
    if ([lines count] <= 0) {
        return textBlocks;
    }
    
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
@end
