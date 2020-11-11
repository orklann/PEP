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
    NSArray *glyphs = [[page textParser] readOrderGlyphs];
    GGlyph *prevGlyph = [glyphs firstObject];
    NSMutableString *currentTJ = [NSMutableString string];
    [currentTJ appendString:[self startTJWithGlyph:prevGlyph]];
    int i = 1;
    for (i = 1; i < [glyphs count]; ++i) {
        GGlyph *nextGlyph = [glyphs objectAtIndex:i];
        if ([self glyph:prevGlyph inSameLineWithGlyph:nextGlyph]) {
            if ([nextGlyph delta] == 0) {
                [currentTJ appendString:[nextGlyph literalString]];
            } else {
                [currentTJ appendString:kEndString];
                [currentTJ appendString:[self startStringWithGlyph:nextGlyph]];
            }
        } else {
            [currentTJ appendString:kEndTJ];
            [result appendString:currentTJ];
            currentTJ = [NSMutableString string];
            [currentTJ appendString:[self startTJWithGlyph:nextGlyph]];
        }
        prevGlyph = nextGlyph;
    }
    
    // End last TJ command
    [currentTJ appendString:[self endTJ]];
    [result appendString:currentTJ];
    [result appendString:@"Q\n"];
    return result;
}

- (BOOL)glyph:(GGlyph*)g1 inSameLineWithGlyph:(GGlyph*)g2 {
    NSPoint p1 = [g1 frame].origin;
    NSPoint p2 = [g2 frame].origin;
    
    if (p1.y == p2.y && // 1: The same y
        [[g1 fontName] isEqualToString:[g2 fontName]]) { // 2: Same font name
        
        NSRect f1 = [g1 frame];
        NSRect f2 = [g2 frame];
        CGFloat maxX = NSMaxX(f1);
        CGFloat minX = NSMinX(f2);
        // If next glyph (g2) delta is 0, but maxX != minX, means g1 and g2
        // should not in the same TJ (same line), because g2's text matrix was
        // setting by separately with other operators, like (Td, Tm, etc)
        // To make glyphs position exactly as its before compilation
        if ([g2 delta] == 0 && maxX != minX) {
            return NO;
        }
        return YES;
    }
    return NO;
}

- (NSString*)startTJWithGlyph:(GGlyph*)g {
    CGAffineTransform ctm = [g ctm];
    CGAffineTransform textMatrix = [g textMatrix];
    NSMutableString *result = [NSMutableString string];
    [result appendString:@"\nq\nQ\nq\n"];
    
    // cm operator
    NSString *cm = [NSString stringWithFormat:@"%f %f %f %f %f %f cm\n",
                                ctm.a, ctm.b, ctm.c, ctm.d, ctm.tx, ctm.ty];
    
    [result appendString:cm];
    
    // BT
    [result appendString:@"BT\n"];
    
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
        return [NSString stringWithFormat:@" %d (%@", [g delta], [g literalString]];
    }
    return [NSString stringWithFormat:@"(%@", [g literalString]];
}
@end
