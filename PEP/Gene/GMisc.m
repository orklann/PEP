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

CGFloat getGlyphAdvanceForFont(NSString *ch, NSFont *font) {
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:ch];
    [s addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, 1)];
    [s addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, 1)];

    CFAttributedStringRef attrStr = (__bridge CFAttributedStringRef)(s);
    CTLineRef line = CTLineCreateWithAttributedString(attrStr);
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    CTRunRef firstRun = CFArrayGetValueAtIndex(runs, 0);
    CGSize size;
    CTRunGetAdvances(firstRun, CFRangeMake(0, 1), &size);
    CFRelease(line);
    return size.width;
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

// return -1 if glyph a is before b, return 1 if glyph b is before glyph a
int compareGlyphs(GGlyph *a, GGlyph *b) {
    NSPoint pa = [a frame].origin;
    NSPoint pb = [b frame].origin;
    
    CGFloat aMaxY = NSMaxY([a frame]);
    CGFloat bMaxY = NSMaxY([b frame]);
    CGFloat aMaxX = NSMaxX([a frame]);
    CGFloat bMaxX = NSMaxX([a frame]);
    
    // if two glyphs are located at more or less the same y coordinate,
    // the one to the left goes before, if not, else the one which start
    // higher up is sorted first.
    CGFloat tolerance = 0.04f;
    CGFloat percent = fabs(pa.y - pb.y) / (pa.y + pb.y);
    int ret = -1;
    if (percent <= tolerance) {
       if (pa.x < pb.x) {
           ret = -1;
           return ret;
       } else {
           ret = 1;
           return ret;
       }
    }
    
    // if one glyph is located above another, it goese before
    if (aMaxY > pb.y) {
        return -1;
    }
    
    if (pa.y < bMaxY) {
        return 1;
    }
    
    
    // if one glyph is to the left, is goese befor
    if (aMaxX < pb.x) {
        return -1;
    }
    
    if (pa.x > bMaxX) {
        return 1;
    }
    
    return ret;
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

NSMutableArray *sortGlyphsInReadOrder(NSMutableArray *glyphs) {
    NSMutableArray *sorted = [NSMutableArray array];
    while([glyphs count] > 0) {
        GGlyph *smallest = [glyphs firstObject];
        int i;
        int smallestIndex = 0;
        for (i = 1; i < [glyphs count]; i++) {
            GGlyph *g = [glyphs objectAtIndex:i];
            if (compareGlyphs(smallest, g) == 1) {
                smallestIndex = i;
                smallest = [glyphs objectAtIndex:smallestIndex];
            }
        }
        [sorted addObject:smallest];
        [glyphs removeObject:smallest];
    }
    return sorted;
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

NSPoint translatePoint(NSPoint p, NSPoint newOrigin) {
    CGFloat nx = p.x + newOrigin.x;
    CGFloat ny = p.y + newOrigin.y;
    return NSMakePoint(nx, ny);
}

NSString* setToString(NSSet* set) {
    NSString *chars = [[set allObjects] componentsJoinedByString:@""];
    return chars;
}

void printTableTagsForCGFont(CGFontRef font) {
    CFArrayRef tags = CGFontCopyTableTags(font);
    int tableCount = (int)CFArrayGetCount(tags);
    for (int index = 0; index < tableCount; ++index) {
        uint32_t aTag = (uint32_t)CFArrayGetValueAtIndex(tags, index);

        unsigned char bytes[4];
        unsigned long n = aTag;

        bytes[0] = (n >> 24) & 0xFF;
        bytes[1] = (n >> 16) & 0xFF;
        bytes[2] = (n >> 8) & 0xFF;
        bytes[3] = n & 0xFF;
        NSLog(@"%c%c%c%c", bytes[0], bytes[1], bytes[2], bytes[3]);
    }
}
