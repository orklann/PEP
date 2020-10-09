//
//  GMisc.m
//  PEP
//
//  Created by Aaron Elkins on 9/18/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "GMisc.h"
#import "GGlyph.h"
#import "GWord.h"
#import "GLine.h"

void printData(NSData *data) {
    NSUInteger i;
    unsigned char * bytes = (unsigned char*)[data bytes];
    printf("\n");
    for (i = 0; i < [data length]; i++) {
        printf("%c", (unsigned char)(*(bytes+i)));
    }
    printf("\n");
    printf("\n");
}


// TODO: Since this method is not always returning a correct value,
// We are considering use other methods.
CGFloat getGlyphAdvanceForFont(NSString *ch, NSFont *font) {
    CTFontRef ctFont = (__bridge CTFontRef)font;
    CGFontRef f = CTFontCopyGraphicsFont(ctFont, nil);
    
    CGGlyph g = CGFontGetGlyphWithGlyphName(f, (__bridge CFStringRef)ch);
    int advance;
    // This advance is :1517 for example it's not relative to font size.
    // It's advance in glyph space (EM square)
    CGFontGetGlyphAdvances(f, &g, 1, &advance);
    
    CGSize size;
    
    CTFontGetAdvancesForGlyphs(ctFont, kCTFontOrientationHorizontal, &g, &size, 1);
    NSLog(@"(*)advance: %@ %@", NSStringFromSize(size), ch);
    NSLog(@"advance: %d : %@", advance, ch);
    int upm = CGFontGetUnitsPerEm(f);
    NSLog(@"upm: %d", upm);
    
    CGFloat glyphWidth = (CGFloat) (advance * [font pointSize])/ upm;
    CFRelease(f);
    return glyphWidth;
}

// TODO: Since getGlyphAdvanceForFont() is not always returning a correct value
// We are considering rewrite this method with an advance as input parameter
NSRect getGlyphBoundingBox(NSString *ch, NSFont *font, CGAffineTransform tm,
                           CGFloat advance) {
    CGFloat glyphWidth = advance;
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc]
                                    initWithString:ch];
    [s addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [ch length])];
    [s addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor]
              range:NSMakeRange(0, [ch length])];
    CFAttributedStringRef attrStr = (__bridge CFAttributedStringRef)(s);
    CTLineRef line = CTLineCreateWithAttributedString(attrStr);
    CGFloat ascent, descent, leading;
    CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    CGRect textRect = NSMakeRect(0, 0 - descent, glyphWidth, descent + ascent);
    CGRect r = CGRectApplyAffineTransform(textRect, tm);
    CFRelease(line);
    return r;
}

// return -1 if glyph a is before b, return 1 if glyph b is before glyph a
int compareGlyphs(GGlyph *a, GGlyph *b) {
    NSPoint pa = [a frame].origin;
    NSPoint pb = [b frame].origin;
    
    // if one glyph is located above another, it goese before
    if (pa.y >= pb.y) {
        return -1;
    } else if (pb.y > pa.y){
        return 1;
    }
    
    // if one glyph is to the left, is goese befor
    if (pa.x <= pb.x) {
        return -1;
    } else if (pb.x < pa.x) {
        return 1;
    }
    
    return -1;
}

void quicksortGlyphs(NSMutableArray *array, int l, int r) {
    if (l >= r) {
        return ;
    }
     
    GGlyph *pivot = [array objectAtIndex:(int)r];
    int cnt = l;
     
    for (int i = l; i <= r; i++)
    {
        GGlyph *a = [array objectAtIndex:i];
        // If an element less than or equal to the pivot is found...
        if (compareGlyphs(pivot, a) == 1) {
         // Then swap arr[cnt] and arr[i] so that the smaller element arr[i]
         // is to the left of all elements greater than pivot
         [array exchangeObjectAtIndex:i withObjectAtIndex:cnt];

         // Make sure to increment cnt so we can keep track of what to swap
         // arr[i] with
         cnt++;
        }
    }
    
    // TODO: Buggy? Let's check later
    // Means all elements are sorted correctly, stop sorting.
    if (cnt == l) {
        return ;
    }
    
    // NOTE: cnt is currently at one plus the pivot's index
    // (Hence, the cnt-2 when recursively sorting the left side of pivot)
    quicksortGlyphs(array, l, cnt-2); // Recursively sort the left side of pivot
    quicksortGlyphs(array, cnt, r);   // Recursively sort the right side of pivot
}

BOOL separateCharacters(GGlyph *a, GGlyph *b) {
    NSRect f1 = [a frame];
    NSRect f2 = [b frame];
    CGFloat yMinA = NSMinY(f1);
    CGFloat yMinB = NSMinY(f2);
    CGFloat xA = NSMaxX(f1);
    CGFloat xB = NSMinX(f2);
    CGFloat widthA = NSWidth(f1);
    CGFloat widthB = NSWidth(f2);
    CGFloat heightA = NSHeight(f1);
    CGFloat heightB = NSHeight(f1);
    
    CGFloat dy = fabs(yMinA - yMinB);
    CGFloat heightTolerance = fabs(heightA - heightB);
    if (dy <= heightTolerance) {
        CGFloat dx = fabs(xA - xB);
        CGFloat widthTolerance = (widthA + widthB) / 2.0;
        if (dx <= widthTolerance) {
            return YES;
        }
    }
    
    return NO;
}

BOOL separateWords(GWord* a, GWord*b) {
    NSRect f1 = [a frame];
    NSRect f2 = [b frame];
    CGFloat yMinA = NSMinY(f1);
    CGFloat yMinB = NSMinY(f2);
    CGFloat xA = NSMaxX(f1);
    CGFloat xB = NSMinX(f2);
    CGFloat widthA = NSWidth([[[a glyphs] lastObject] frame]);
    CGFloat widthB = NSWidth([[[b glyphs] firstObject] frame]);
    CGFloat heightA = NSHeight(f1);
    CGFloat heightB = NSHeight(f1);
    
    CGFloat dy = fabs(yMinA - yMinB);
    CGFloat heightTolerance = fabs(heightA - heightB);
    if (dy <= heightTolerance) {
        CGFloat dx = fabs(xA - xB);
        CGFloat widthTolerance = (widthA + widthB) / 2.0;
        if (dx <= widthTolerance) {
            return YES;
        }
    }
    
    return NO;
}

CGFloat distance(NSPoint a, NSPoint b) {
    CGFloat dx = MAX(a.x - b.x, 0);
    CGFloat dy = MAX(a.y - b.y, 0);
    return sqrt((dx*dx) + (dy*dy));
}

BOOL separateLines(GLine *a, GLine *b) {
    NSRect f1 = [a frame];
    NSRect f2 = [b frame];
    CGFloat xA = NSMinX(f1);
    CGFloat xB = NSMinX(f2);
    
    NSPoint pa = NSMakePoint(xA, NSMinY(f1));
    NSPoint pb = NSMakePoint(xB, NSMaxY(f2));
    
    CGFloat heightA = NSHeight([a frame]);
    CGFloat heightB = NSHeight([b frame]);
    
    
    CGFloat xTolerance = 5; // Fix value: 5 points
    CGFloat heightTolerance = 0.05; // Percentage
    CGFloat yTolerance = (heightA + heightB) / 2;
    
    if (fabs(xA - xB) <= xTolerance && distance(pa, pb) <= yTolerance
        && fabs(heightA - heightB) / ((heightA + heightB) / 2) <= heightTolerance) {
        return YES;
    }
    
    return NO;
}
