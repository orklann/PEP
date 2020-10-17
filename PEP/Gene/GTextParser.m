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
    
    // Add heading space glyphs as first word
    int start = 0;
    GWord *firstWord = [GWord create];
    GGlyph *currentGlyph = [glyphs objectAtIndex:start];
    while(start <= [glyphs count] - 1){
        if ([[currentGlyph content] isEqualToString:@" "]) {
            [firstWord addGlyph:currentGlyph];
        } else {
            break;
        }
        start++;
        currentGlyph = [glyphs objectAtIndex:start];
    }
    
    // Add first word
    [words addObject:firstWord];
    
    // Remove heading space glyphs by splitting glyphs array
    int splitStart = start;
    int len = (int)([glyphs count] - splitStart);
    NSArray *firstSplit = [glyphs subarrayWithRange:NSMakeRange(splitStart, len)];
    
    // Add trailing space glyphs as last word
    start = (int)[glyphs count] - 1;
    len = 0;
    GWord *lastWord = [GWord create];
    currentGlyph = [glyphs objectAtIndex:start];
    while(start >= 0) {
        if ([[currentGlyph content] isEqualToString:@" "]) {
            [lastWord addGlyph:currentGlyph];
            len++;
        } else {
            break;
        }
        start--;
        currentGlyph = [glyphs objectAtIndex:start];
    }
    
    // Remove trailing space glyphs by splitting glyphs array
    len = (int)[firstSplit count] - len;
    NSArray *secondSplit = [firstSplit subarrayWithRange:NSMakeRange(0, len)];
    
    // Normal process to add words (spaces are treated as one word)
    // Continuous spaces are treated as one word
    currentGlyph = [secondSplit objectAtIndex:0];
    GWord *word = [GWord create];
    [word addGlyph:currentGlyph];
    int i;
    for (i = 1; i < [secondSplit count]; i++) {
        GGlyph *nextGlyph = [secondSplit objectAtIndex:i];
        if ([[nextGlyph content] isEqualToString:@" "] ||
            i == [secondSplit count] - 1) {
            // End and add current word
            if (i == [secondSplit count] - 1 && ![[nextGlyph content] isEqualToString:@" "]) {
                [word addGlyph:nextGlyph];
            }
            [words addObject:word];
            
            // Add spaces glyphs into one word
            if ([[nextGlyph content] isEqualToString:@" "]) {
                word = [GWord create];
                [word addGlyph:nextGlyph];
                nextGlyph = [secondSplit objectAtIndex:i+1];
                if ([[nextGlyph content] isEqualToString:@" "]) {
                    i++;
                }
                
                while ([[nextGlyph content] isEqualToString:@" "]) {
                    [word addGlyph:nextGlyph];
                    i++;
                    nextGlyph = [secondSplit objectAtIndex:i];
                }
                
                [words addObject:word];
            }

            // Start next word
            word = [GWord create];
            if (i + 1 <= [secondSplit count] - 1) {
                currentGlyph = [secondSplit objectAtIndex:i+1];
                [word addGlyph:currentGlyph];
            }
            i++;
            continue;
        }
        
        // Current glyph and next glyph can be two continue characters
        // Just add next glyph into current word
        if (separateCharacters(currentGlyph, nextGlyph)) {
            [word addGlyph:nextGlyph];
            currentGlyph = nextGlyph;
        }
    }
    
    // Add last word if it contains any glyphs
    if ([[lastWord glyphs] count] > 0) {
        [words addObject:lastWord];
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
