//
//  GMisc.m
//  PEP
//
//  Created by Aaron Elkins on 9/18/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "GMisc.h"

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

CGFloat getGlyphAdvanceForFont(NSString *ch, NSFont *font) {
    CTFontRef ctFont = (__bridge CTFontRef)font;
    CGFontRef f = CTFontCopyGraphicsFont(ctFont, nil);
    
    CGGlyph g = CGFontGetGlyphWithGlyphName(f, (__bridge CFStringRef)ch);
    int advance;
    // This advance is :1517 for example it's not relative to font size.
    // It's advance in glyph space (EM square)
    CGFontGetGlyphAdvances(f, &g, 1, &advance);
    //NSLog(@"advance: %d", advance);
    int upm = CGFontGetUnitsPerEm(f);
    //NSLog(@"upm: %d", upm);
    
    CGFloat glyphWidth = (CGFloat) (advance * [font pointSize] )/ upm;
    
    CFRelease(ctFont);
    CFRelease(f);
    return glyphWidth;
}

NSRect getGlyphBoundingBox(NSString *ch, NSFont *font, CGAffineTransform tm) {
    CGFloat glyphWidth = getGlyphAdvanceForFont(ch, font);
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
