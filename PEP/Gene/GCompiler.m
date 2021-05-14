//
//  GCompiler.m
//  PEP
//
//  Created by Aaron Elkins on 11/10/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GCompiler.h"
#import "GGlyph.h"
#import "GPage.h"
#import "GMisc.h"

#define kEndString @")"
#define kEndTJ @") ] TJ\nET\n"

@implementation GCompiler
+ (id)compilerWithPage:(GPage*)page {
    GCompiler *comp = [[GCompiler alloc] init];
    [comp setPage:page];
    return comp;
}

- (void)setPage:(GPage*)p {
    page = p;
}

- (NSString*)compile {
    NSMutableString *result = [NSMutableString string];
    [result appendString:@"q"];
    NSArray *source = [self buildGlyphsGroupArray];
    for (id obj in source) {
        if ([obj isKindOfClass:[NSMutableArray class]]) {
            [result appendString:[self compileGlyphsArray:obj]];
        } else {
            //[result appendString:[obj compile]];
        }
    }
    [result appendString:@"Q"];
    return result;
}

- (NSString*)compileGlyphsArray:(NSArray*)glyphs {
    NSMutableString *result = [NSMutableString string];
    GGlyph *prevGlyph = [glyphs firstObject];
    
    currentWordSpace = [prevGlyph wordSpace];
    currentCharSpace = [prevGlyph characterSpace];
    
    NSMutableString *currentTJ = [NSMutableString string];
    [currentTJ appendString:[self startTJWithGlyph:prevGlyph]];
    int i = 1;
    for (i = 1; i < [glyphs count]; ++i) {
        GGlyph *nextGlyph = [glyphs objectAtIndex:i];
        if ([self glyph:prevGlyph inSameLineWithGlyph:nextGlyph]) {
            // Calculate next glyph delta from prev glyph and update it
            CGFloat delta = [self getDeltaFromGlyph:nextGlyph toGlyph:prevGlyph];
            delta *= -1;
            [nextGlyph setDelta:delta];
            if ([nextGlyph delta] == 0) {
                [currentTJ appendString:[nextGlyph literalString]];
            } else {
                [currentTJ appendString:kEndString];
                [currentTJ appendString:[self startStringWithGlyph:nextGlyph]];
            }
        } else {
            [currentTJ appendString:kEndTJ];
            [result appendString:currentTJ];
            currentWordSpace = [nextGlyph wordSpace];
            currentCharSpace = [nextGlyph characterSpace];
            currentTJ = [NSMutableString string];
            [nextGlyph setDelta:0.0];
            [currentTJ appendString:[self startTJWithGlyph:nextGlyph]];
        }
        prevGlyph = nextGlyph;
    }
    
    // End last TJ command
    [currentTJ appendString:[self endTJ]];
    [result appendString:currentTJ];
    return result;
}

- (BOOL)glyph:(GGlyph*)g1 inSameLineWithGlyph:(GGlyph*)g2 {
    NSPoint p1 = [g1 frame].origin;
    NSPoint p2 = [g2 frame].origin;
    
    if (p1.y == p2.y && // 1: The same y
        [[g1 fontName] isEqualToString:[g2 fontName]]) { // 2: Same font name
        /*
         * TODO: I don't know excatly this code is for, But I think we should look at it
         *       if we encounter some compiler bugs.
        NSRect f1 = [g1 frame];
        NSRect f2 = [g2 frame];
        CGFloat maxX = NSMaxX(f1);
        CGFloat minX = NSMinX(f2);
        // If next glyph (g2) delta is 0, but maxX != minX, means g1 and g2
        // should not in the same TJ (same line), because g2's text matrix was
        // setting by separately with other operators, like (Td, Tm, etc)
        // To make glyphs position exactly as its before compilation
        if ([g2 delta] == 0 && maxX != minX) {
            printf("\ndelta = 0\n");
            return NO;
        }*/
        return YES;
    }
    return NO;
}

- (NSString*)startTJWithGlyph:(GGlyph*)g {
    CGAffineTransform ctm = [g ctm];
    CGAffineTransform textMatrix = [g textMatrix];
    NSMutableString *result = [NSMutableString string];
    [result appendString:@"\nQ\nq\n"];
    
    // cm operator
    NSString *cm = [NSString stringWithFormat:@"%f %f %f %f %f %f cm\n",
                                ctm.a, ctm.b, ctm.c, ctm.d, ctm.tx, ctm.ty];
    
    [result appendString:cm];
    
    // BT
    [result appendString:@"BT\n"];
    
    // Tw operator
    [result appendFormat:@"%f Tw\n", currentWordSpace];
    
    // Tc operator
    [result appendFormat:@"%f Tc\n", currentCharSpace];
    
    // Tm operator
    NSString *tm = [NSString stringWithFormat:@"%f %f %f %f %f %f Tm\n",
                    textMatrix.a, textMatrix.b, textMatrix.c, textMatrix.d,
                    textMatrix.tx, textMatrix.ty];
    [result appendString:tm];
    
    // Tf operator
    // Use 1.0 font size, fontSize is always 1.0, we set it in GInterpreter
    [result appendFormat:@"/%@ %f Tf\n", [g fontName], [g fontSize]];
    
    [result appendString:@"[ "];
    
    [result appendString:[self startStringWithGlyph:g]];
    return result;
}

- (NSString*)endTJ {
    return @") ] TJ\nET\n";
}

- (NSString*)startStringWithGlyph:(GGlyph*)g {
    if ([g delta] != 0) {
        return [NSString stringWithFormat:@" %f (%@", [g delta], [g literalString]];
    }
    return [NSString stringWithFormat:@"(%@", [g literalString]];
}

- (CGFloat)getDeltaFromGlyph:(GGlyph*)nextGlyph toGlyph:(GGlyph*)prevGlyph {
    CGFloat delta = 0;
    
    // From text space distance to delta
    CGFloat h = 1.0; // we hardcode here, we need this in graphics state
    CGFloat cs = [prevGlyph characterSpace];
    CGFloat wc = [prevGlyph wordSpace];
    CGFloat fs = [prevGlyph fs];
    
    CGAffineTransform tm1 = [prevGlyph textMatrix];
    tm1.tx += [prevGlyph width];
    
    CGAffineTransform tm2 = [nextGlyph textMatrix];
    
    // Scale down distance by tm2.a (x-scale) if fs is 1.0.
    // fs is 1.0 means: we must take acount of font size in tm2.a,
    // other wise, fs will be tack acount in
    // delta = (glyphDistance / h - wc - cs) / fs * 1000.0;
    CGFloat glyphDistance;
    if (fs == 1.0) {
        glyphDistance = (tm2.tx - tm1.tx) / tm2.a;
    } else {
        glyphDistance = (tm2.tx - tm1.tx);
    }
    
    // Reverse from GInterpeter layoutStrings method
    // See "9.4.4 Text space details"
    delta = (glyphDistance / h - wc - cs) / fs * 1000.0;
    return delta;
}

/*
 * Build page's graphicElements into array, which contains operators, and array of
 * glyphs in the same order in graphic elements array
 * For example:
 *      1). In graphicElememnts: operator1, operator2, glyph1, glyph2, operator3
 *      2). After calling this method, it returns an array, which has:
 *          operator1, operator2, NSArray (glyph1, glyph2), operator3
 *      3). We compile operator, by calling its compile method
 *          We compile NSArray of glyphs, by calling complieGlhphs: method of this clsss
 */

- (NSArray*)buildGlyphsGroupArray {
    return [self buildGlyphsGroupArray:page.graphicElements];
}

- (NSArray*)buildGlyphsGroupArray:(NSArray*)originalArray {
    NSMutableArray *result = [NSMutableArray array];
    BOOL startGlyphsArray = NO;
    NSMutableArray *currentGlyphsArray;
    for (id obj in originalArray) {
        if ([[obj className] isEqualToString:@"GGlyph"] &&
            startGlyphsArray == NO) {
            startGlyphsArray = YES;
            currentGlyphsArray = [NSMutableArray array];
        } else if (![[obj className] isEqualToString:@"GGlyph"]) {
            if (startGlyphsArray) {
                startGlyphsArray = NO;
                [result addObject:currentGlyphsArray];
                currentGlyphsArray = [NSMutableArray array];
            }
        }
        
        if (startGlyphsArray) {
            [currentGlyphsArray addObject:obj];
        } else {
            [result addObject:obj];
        }
    }
    
    if ([currentGlyphsArray count] > 0) {
        [result addObject:currentGlyphsArray];
    }
    
    return result;
}
@end
