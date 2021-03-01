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
#import "GTextBlock.h"
#import "GBinaryData.h"
#import "GConstants.h"
#import "GTJText.h"

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

void printNSStringHex(NSString *s) {
    printf("\n");
    int i;
    for (i = 0; i < [s length]; i++) {
        printf("%x ", [s characterAtIndex:i]);
    }
    printf("\n\n");
}

// return -1 if glyph a is before b, return 1 if glyph b is before glyph a
int compareGlyphs(GGlyph *a, GGlyph *b) {
    NSPoint pa = [a frame].origin;
    NSPoint pb = [b frame].origin;
    
    if (NSEqualPoints(pa, pb)) {
        // Two glyphs has the same origin, we return the one which is a return
        // glyph
        if (isReturnGlyph(a)) {
            return -1;
        } else if (isReturnGlyph(b)) {
            return 1;
        }
    }
    
    CGFloat aMaxY = NSMaxY([a frame]);
    CGFloat bMaxY = NSMaxY([b frame]);
    CGFloat aMaxX = NSMaxX([a frame]);
    CGFloat bMaxX = NSMaxX([b frame]);
    CGFloat aMidY = NSMidY([a frame]);
    CGFloat bMidY = NSMidY([b frame]);

    
    // if two glyphs are located at more or less the same y coordinate,
    // the one to the left goes before, if not, else the one which start
    // higher up is sorted first.
    CGFloat aHeight = [a frame].size.height;
    CGFloat bHeight = [b frame].size.height;
    
    CGFloat tolerance = 0.1;
    int ret = -1;
    if (fabs(pa.y - pb.y) / fabs(aHeight + bHeight) <= tolerance) {
        if (pa.x < pb.x) {
            ret = -1;
            return ret;
        } else {
            ret = 1;
            return ret;
        }
    }
    
    if (aMidY <= bMidY) return 1;
    
    if (bMidY <= aMidY) return -1;
    
    // if one glyph is located above another, it goese before
    if (aMaxY > pb.y) {
        return -1;
    }
    
    if (pa.y < bMaxY) {
        return 1;
    }
    
    
    // if one glyph is to the left, is goes before
    if (aMaxX < pb.x) {
        return -1;
    }
    
    if (pa.x > bMaxX) {
        return 1;
    }
    
    return ret;
}

// return -1 if GTJText a is before b, return 1 if GTJText b is before a
int compareTJTexts(GTJText *a, GTJText *b) {
    NSPoint pa = [a frame].origin;
    NSPoint pb = [b frame].origin;

    
    CGFloat aMaxY = NSMaxY([a frame]);
    CGFloat bMaxY = NSMaxY([b frame]);
    CGFloat aMaxX = NSMaxX([a frame]);
    CGFloat bMaxX = NSMaxX([b frame]);
    CGFloat aMidY = NSMidY([a frame]);
    CGFloat bMidY = NSMidY([b frame]);

    
    // if two GTJTexts are located at more or less the same y coordinate,
    // the one to the left goes before, if not, else the one which start
    // higher up is sorted first.
    CGFloat aHeight = [a frame].size.height;
    CGFloat bHeight = [b frame].size.height;
    
    CGFloat tolerance = 0.1;
    int ret = -1;
    if (fabs(pa.y - pb.y) / fabs(aHeight + bHeight) <= tolerance) {
        if (pa.x < pb.x) {
            ret = -1;
            return ret;
        } else {
            ret = 1;
            return ret;
        }
    }
    
    if (aMidY <= bMidY) return 1;
    
    if (bMidY <= aMidY) return -1;
    
    // if one GTJText is located above another, it goese before
    if (aMaxY > pb.y) {
        return -1;
    }
    
    if (pa.y < bMaxY) {
        return 1;
    }
    
    
    // if one GTJText is to the left, is goes before
    if (aMaxX < pb.x) {
        return -1;
    }
    
    if (pa.x > bMaxX) {
        return 1;
    }
    
    return ret;
}

BOOL glyphsInTheSameLine(GGlyph *a, GGlyph *b) {
    NSPoint originA = [a frame].origin;
    NSPoint originB = [b frame].origin;
    CGFloat delta = 3.0; // TODO: Need refine?
    if (fabs(originA.y - originB.y) <= delta) {
        return YES;
    }
    return NO;
}

NSMutableArray* quicksortGlyphs(NSMutableArray *array) {
    NSMutableArray *less = [NSMutableArray array];
    NSMutableArray *greater = [NSMutableArray array];
    NSMutableArray *result = [NSMutableArray array];
    if ([array count] > 1) {
        // Choose pivot to the middle can improve the performance
        // If all glyphs in array is sorted already
        int pivotIndex = (int)([array count] / 2);
        GGlyph *pivot = [array objectAtIndex:pivotIndex];
        for (GGlyph *g in array) {
            if ([g isEqualTo:pivot]) {
                continue;
            }
            if (compareGlyphs(pivot, g) == 1) { // less, g is before pivot
                [less addObject:g];
            } else if (compareGlyphs(pivot, g) == -1) { // greater, g is after pivot
                [greater addObject:g];
            }
        }
        [result addObjectsFromArray:quicksortGlyphs(less)];
        [result addObject:pivot];
        [result addObjectsFromArray:quicksortGlyphs(greater)];
        return result;
    } else {
        return array;
    }
    
    return array;
}

NSMutableArray* quicksortGTJTexts(NSMutableArray *array) {
    NSMutableArray *less = [NSMutableArray array];
    NSMutableArray *greater = [NSMutableArray array];
    NSMutableArray *result = [NSMutableArray array];
    if ([array count] > 1) {
        // Choose pivot to the middle can improve the performance
        // If all glyphs in array is sorted already
        int pivotIndex = (int)([array count] / 2);
        GTJText *pivot = [array objectAtIndex:pivotIndex];
        for (GTJText *t in array) {
            if ([t isEqualTo:pivot]) {
                continue;
            }
            if (compareTJTexts(pivot, t) == 1) { // less, g is before pivot
                [less addObject:t];
            } else if (compareTJTexts(pivot, t) == -1) { // greater, g is after pivot
                [greater addObject:t];
            }
        }
        [result addObjectsFromArray:quicksortGlyphs(less)];
        [result addObject:pivot];
        [result addObjectsFromArray:quicksortGlyphs(greater)];
        return result;
    } else {
        return array;
    }
    
    return array;
}

/*
 * Note: I am ok with this implementation, but I also notice that we might
 * change it - the compareGlyphs() function.
 * Because in text editor, line breaks can bring some glyphs frame in next line
 * which break the read order glyphs, that is glyphs in next line exceed upwards
 * to previous line. (mainly due to not even glyphs height, some high enough to
 * exceed the bottom line of previous line.
 * TODO: So shall we handle this later?
 */
NSMutableArray *sortGlyphsInReadOrder(NSMutableArray *glyphs) {
    NSMutableArray *sorted = quicksortGlyphs(glyphs);
    /* ** Slow code for sorting, we use quick sort to have better performance */
    /*
    NSMutableArray *workingGlyphs = [NSMutableArray arrayWithArray:glyphs];
    NSMutableArray *sorted = [NSMutableArray array];
    while([workingGlyphs count] > 0) {
        GGlyph *smallest = [workingGlyphs firstObject];
        int i;
        int smallestIndex = 0;
        for (i = 1; i < [workingGlyphs count]; i++) {
            GGlyph *g = [workingGlyphs objectAtIndex:i];
            if (compareGlyphs(smallest, g) == 1) {
                smallestIndex = i;
                smallest = [workingGlyphs objectAtIndex:smallestIndex];
            }
        }
        [sorted addObject:smallest];
        [workingGlyphs removeObject:smallest];
    }*/
    return sorted;
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
    CGFloat heightTolerance = (heightA + heightB) * 0.05;
    if (dy <= heightTolerance) {
        CGFloat dx = fabs(xA - xB);
        CGFloat widthTolerance = (widthA + widthB);
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
    
    NSPoint pa = f1.origin;
    NSPoint pb = f2.origin;
    
    CGFloat heightA = NSHeight([a frame]);
    CGFloat heightB = NSHeight([b frame]);
    
    
    CGFloat xTolerance = kLinesPostionThresold;
    CGFloat heightTolerance = 0.05; // Percentage
    CGFloat yTolerance = (heightA + heightB) / 2 + ((heightA + heightB) * 0.3);
    
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

//=============== NSData fontDataForCGFont(CGFontRef cgFont) ==============
typedef struct FontHeader {
    int32_t fVersion;
    uint16_t fNumTables;
    uint16_t fSearchRange;
    uint16_t fEntrySelector;
    uint16_t fRangeShift;
} FontHeader;

typedef struct TableEntry {
    uint32_t fTag;
    uint32_t fCheckSum;
    uint32_t fOffset;
    uint32_t fLength;
} TableEntry;

static uint32_t CalcTableCheckSum(const uint32_t *table, uint32_t numberOfBytesInTable) {
    uint32_t sum = 0;
    uint32_t nLongs = (numberOfBytesInTable + 3) / 4;
    while (nLongs-- > 0) {
       sum += CFSwapInt32HostToBig(*table++);
    }
    return sum;
}

//static uint32_t CalcTableDataRefCheckSum(CFDataRef dataRef) {
//    const uint32_t *dataBuff = (const uint32_t *)CFDataGetBytePtr(dataRef);
//    uint32_t dataLength = (uint32_t)CFDataGetLength(dataRef);
//    return CalcTableCheckSum(dataBuff, dataLength);
//}

// Original code from here: https://gist.github.com/Jyczeal/1892760

NSData* fontDataForCGFont(CGFontRef cgFont) {
    if (!cgFont) {
        return nil;
    }
    
    CFRetain(cgFont);
    CFArrayRef tags = CGFontCopyTableTags(cgFont);
    int tableCount = (int)CFArrayGetCount(tags);
    size_t *tableSizes = malloc(sizeof(size_t) * tableCount);
    memset(tableSizes, 0, sizeof(size_t) * tableCount);
    BOOL containsCFFTable = NO;
    size_t totalSize = sizeof(FontHeader) + sizeof(TableEntry) * tableCount;
    for (int index = 0; index < tableCount; ++index) {
        //get size
        size_t tableSize = 0;
        uint32_t aTag = (uint32_t)CFArrayGetValueAtIndex(tags, index);
        if (aTag == 'CFF ' && !containsCFFTable) {
            containsCFFTable = YES;
        }
        CFDataRef tableDataRef = CGFontCopyTableForTag(cgFont, aTag);
        if (tableDataRef != NULL) {
                tableSize = CFDataGetLength(tableDataRef);
                CFRelease(tableDataRef);
        }
        totalSize += (tableSize + 3) & ~3;
        tableSizes[index] = tableSize;
    }
    
    unsigned char *stream = malloc(totalSize);
    memset(stream, 0, totalSize);
    char* dataStart = (char*)stream;
    char* dataPtr = dataStart;
    
    // compute font header entries
    uint16_t entrySelector = 0;
    uint16_t searchRange = 1;
    while (searchRange < tableCount >> 1) {
            entrySelector++;
            searchRange <<= 1;
    }
    searchRange <<= 4;
    uint16_t rangeShift = (tableCount << 4) - searchRange;
    // write font header (also called sfnt header, offset subtable)
    FontHeader* offsetTable = (FontHeader*)dataPtr;
    
    //OpenType Font contains CFF Table use 'OTTO' as version, and with .otf extension
    //otherwise 0001 0000
    offsetTable->fVersion = containsCFFTable ? 'OTTO' : CFSwapInt16HostToBig(1);
    offsetTable->fNumTables = CFSwapInt16HostToBig((uint16_t)tableCount);
    offsetTable->fSearchRange = CFSwapInt16HostToBig((uint16_t)searchRange);
    offsetTable->fEntrySelector = CFSwapInt16HostToBig((uint16_t)entrySelector);
    offsetTable->fRangeShift = CFSwapInt16HostToBig((uint16_t)rangeShift);
    dataPtr += sizeof(FontHeader);
    // write tables
    TableEntry* entry = (TableEntry*)dataPtr;
    dataPtr += sizeof(TableEntry) * tableCount;
    
    for (int index = 0; index < tableCount; ++index) {
        uint32_t aTag = (uint32_t)CFArrayGetValueAtIndex(tags, index);
        CFDataRef tableDataRef = CGFontCopyTableForTag(cgFont, aTag);
        size_t tableSize = CFDataGetLength(tableDataRef);
        memcpy(dataPtr, CFDataGetBytePtr(tableDataRef), tableSize);
        entry->fTag = CFSwapInt32HostToBig((uint32_t)aTag);
        entry->fCheckSum = (uint32_t)CFSwapInt32HostToBig((uint32_t)CalcTableCheckSum((uint32_t *)dataPtr, (uint32_t)tableSize));
        uint32_t offset = (uint32_t)(dataPtr - dataStart);
        entry->fOffset = CFSwapInt32HostToBig((uint32_t)offset);
        entry->fLength = CFSwapInt32HostToBig((uint32_t)tableSize);
        dataPtr += (tableSize + 3) & ~3;
        ++entry;
        CFRelease(tableDataRef);
    }
    
    CFRelease(cgFont);
    free(tableSizes);
    NSData *fontData = [NSData dataWithBytesNoCopy:stream
                                            length:totalSize
                                      freeWhenDone:YES];
    return fontData;
}

NSMutableArray *sortedGBinaryDataArray(NSMutableArray *array) {
    NSMutableArray *ret = [NSMutableArray array];
    while([array count] > 0) {
        GBinaryData *smallest = [array firstObject];
        int i;
        for (i = 1; i < [array count]; i++) {
            GBinaryData *b = [array objectAtIndex:i];
            if (smallest.objectNumber > b.objectNumber) {
                smallest = b;
            }
        }
        [ret addObject:smallest];
        [array removeObject:smallest];
    }
    return ret;
}

NSMutableArray *groupingGBinaryDataArray(NSMutableArray *array) {
    NSMutableArray *result = [NSMutableArray array];
    NSMutableArray *group = nil;
    GBinaryData *prevBinaryData = nil;
    for (GBinaryData *binaryData in array) {
        if (group == nil) {
            group = [NSMutableArray array];
            [group addObject:binaryData];
            prevBinaryData = binaryData;
        } else {
            if ([prevBinaryData objectNumber] == [binaryData objectNumber] - 1) {
                [group addObject:binaryData];
                prevBinaryData = binaryData;
            } else {
                [result addObject:group];
                group = [NSMutableArray array];
                [group addObject:binaryData];
                prevBinaryData = binaryData;
            }
        }
    }
    if (group != nil) {
        [result addObject:group];
    }
    return result;
}

NSString* paddingTenZero(int offset) {
    NSString *numberString = [NSString stringWithFormat:@"%d", offset];
    NSMutableString *ret = [NSMutableString string];
    int left = 10 - (int)[numberString length];
    int i;
    for (i = 0; i < left; i++) {
        [ret appendString:@"0"];
    }
    [ret appendString:numberString];
    return ret;
}

NSString* paddingFiveZero(int generationNumber) {
    NSString *numberString = [NSString stringWithFormat:@"%d", generationNumber];
    NSMutableString *ret = [NSMutableString string];
    int left = 5 - (int)[numberString length];
    int i;
    for (i = 0; i < left; i++) {
        [ret appendString:@"0"];
    }
    [ret appendString:numberString];
    return ret;
}

NSString *buildXRefEntry(int offset, int generationNumber, NSString *state) {
    NSMutableString *entry = [NSMutableString string];
    NSString *offsetString = paddingTenZero(offset);
    NSString *generationString = paddingFiveZero(generationNumber);
    [entry appendFormat:@"%@ ", offsetString];
    [entry appendFormat:@"%@ ", generationString];
    [entry appendFormat:@"%@\r\n", state];
    return entry;
}

void prettyLogForTextBlock(GTextBlock* textBlock) {
    printf("====Text Block====\n");
    NSMutableArray *glyphs = [textBlock glyphs];
    printf("***Glyhphs***\n[");
    int i;
    for (i = 0; i < [glyphs count]; i++) {
        GGlyph *g = [glyphs objectAtIndex:i];
        printf("%s", [[g content] UTF8String]);
    }
    printf("]\n***End Glyphs***\n");
    
    printf("***Lines***\n");
    NSMutableArray *lines = [textBlock lines];
    for (i = 0; i < [lines count]; i++) {
        GLine *l = [lines objectAtIndex:i];
        printf("[Debug][Line:%d] %s\n", i, [[l lineString] UTF8String]);
    }
    printf("***End Lines***\n");
    printf("====End Text Block====\n");
}


void prettyLogForWords(NSArray *words) {
    printf("====Words====\n[");
    printf("[Debug][Words: %d]: ", (int)[words count]);
    int i;
    for (i = 0; i < [words count]; i++) {
        GWord *w = [words objectAtIndex:i];
        NSString *s = [w wordString];
        int index = 0;
        for (index = 0; index < [s length]; ++index) {
            char ch = [s characterAtIndex:index];
            if (isWhiteSpaceChar(ch)) {
                // We use ☀️ to represent white spaces
                printf("%s", [@"☀️" UTF8String]);
            } else {
                printf("%c", ch);
            }
        }
        printf(" ");
    }
    printf("\n====End Words====\n");
}

void prettyLogCharCodesForWords(NSArray * _Nullable words) {
    printf("====Words====\n");
    int i;
    for (i = 0; i < [words count]; i++) {
        GWord *w = [words objectAtIndex:i];
        NSString *s = [w wordString];
        int index = 0;
        printf(" <");
        for (index = 0; index < [s length]; ++index) {
            char ch = [s characterAtIndex:index];
            printf(" [%d - %c] ", ch, ch);
        }
        printf("> ");
    }
    printf("\n====End Words====\n");
}

BOOL isWhiteSpaceChar(char c) {
    if (c == ' ' ||
        c == '\t' ||
        c == '\n' || c == '\r' ||
        c == '\0' || c == 0x09) {
        return YES;
    }
    return NO;
}



BOOL isWhiteSpaceGlyph(GGlyph *glyph) {
    char ch = [[glyph content] characterAtIndex:0];
    return isWhiteSpaceChar(ch);
}

BOOL isReturnChar(char c) {
    if (c == '\n') return YES;
    return NO;
}

BOOL isReturnGlyph(GGlyph * _Nullable glyph) {
    char ch = [[glyph content] characterAtIndex:0];
    return isReturnChar(ch);
}

void logGlyphsIndex(NSArray * _Nullable glyphs) {
    printf("====Glyphs Index====\n");
    printf("Index => [");
    for (NSNumber *n in glyphs) {
        printf("%d ", [n intValue]);
    }
    printf("]");
    printf("\n");
}

void logGlyphsContent(NSArray * _Nullable glyphs) {
    printf("====Glyphs Content====\n");
    printf("Content => [");
    for (GGlyph *g in glyphs) {
        printf("%s", [[g content] UTF8String]);
    }
    printf("]");
    printf("\n");
}

void printCGAffineTransform(CGAffineTransform mt) {
    printf("\n[Debug] a:%f b:%f c:%f d:%f tx:%f, ty:%f\n",
          mt.a, mt.b, mt.c, mt.d, mt.tx, mt.ty);
}

int signOfCGFloat(CGFloat v) {
    if (v <= 0.0) return -1;
    if (v > 0.0) return 1;
    return 0;
}

int getObjectNumber(NSString *ref) {
    NSArray *array = [ref componentsSeparatedByString:@"-"];
    return [[array firstObject] intValue];
}

int getGenerationNumber(NSString *ref) {
    NSArray *array = [ref componentsSeparatedByString:@"-"];
    return [[array lastObject] intValue];
}
