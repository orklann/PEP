//
//  GPage.m
//  PEP
//
//  Created by Aaron Elkins on 9/17/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GPage.h"
#import "GDecoders.h"
#import "GEncoders.h"
#import "GMisc.h"
#import "GInterpreter.h"
#import "GDocument.h"
#import "GFont.h"
#import "GTextParser.h"
#import "GWord.h"
#import "GLine.h"
#import "GTextBlock.h"
#import "GGlyph.h"
#import "GBinaryData.h"

@implementation GPage

+ (id)create {
    GPage *p = [[GPage alloc] init];
    [p setNeedUpdate:YES];
    p.dataToUpdate = [NSMutableArray array];
    p.cachedFonts = [NSMutableDictionary dictionary];
    return p;
}

- (void)setPageDictionary:(GDictionaryObject*)d {
    pageDictionary = d;
}

- (GDictionaryObject*)pageDictionary {
    return pageDictionary;
}

- (void)setParser:(GParser*)p {
    parser = p;
}

- (NSPoint)origin {
    NSRect pageRect = [self calculatePageMediaBox];
    origin = pageRect.origin;
    return origin;
}

- (GParser*)parser {
    return parser;
}

- (GDocument*)doc {
    return doc;
}

- (void)setDocument:(GDocument*)d {
    doc = d;
}

- (void)parsePageContent {
    // Contents can be a GArrayObject instead of GRefObject,
    // TODO: Handle this case later.
    GRefObject *ref = [[pageDictionary value] objectForKey:@"Contents"];
    GStreamObject *contentStream = [parser getObjectByRef:[ref getRefString]];
    pageContent = (NSMutableData*)[contentStream getDecodedStreamContent];
    
    printData(pageContent);
    
    // Automatically parse resources
    [self parseResources];
}

- (void)parseResources {
    GRefObject *ref = [[pageDictionary value] objectForKey:@"Resources"];
    resources = [parser getObjectByRef:[ref getRefString]];
}

- (GDictionaryObject*)resources {
    return resources;
}

- (void)translateToPageOrigin:(CGContextRef)context {
    NSPoint o = [self origin];
    CGContextTranslateCTM(context, o.x, o.y);
}

- (void)render:(CGContextRef)context {
    if (self.needUpdate) {
        [self initGlyphsForFontDict];
    }
    
    // Draw media box (a.k.a page boundary)
    NSRect pageRect = [self calculatePageMediaBox];
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context, pageRect);
    
    // Translate context origin to page media box origin
    [self translateToPageOrigin:context];
    
    textState = [GTextState create];
    graphicsState = [GGraphicsState create];
    textParser = [GTextParser create];
    
    GInterpreter *interpreter = [GInterpreter create];
    [interpreter setPage:self];
    [interpreter setParser:parser];
    [interpreter setInput:pageContent];
    
    if (self.needUpdate) {
        // Build cached fonts for all Tf commands at this time, we have commands
        [interpreter parseCommands]; // commands are saved in this page
        [self buildCachedFonts];
    }
    
    [interpreter eval:context];
    
    if (textEditor != nil) {
        [textEditor draw:context];
    }
    
    // Draw highlith text block border
    CGContextSetLineWidth(context, 1.0 / (kScaleFactor));
    CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
    CGContextStrokeRect(context, highlightBlockFrame);
    
    [self setNeedUpdate:NO];
    
}

// Calculate media box for PDF page in user space coordinate
// Return rect with origin in bottom left
- (NSRect)calculatePageMediaBox {
    GArrayObject *mediaBox = [[pageDictionary value] objectForKey:@"MediaBox"];
    //GNumberObject *xObj = [[mediaBox value] objectAtIndex:0];
    //GNumberObject *yObj = [[mediaBox value] objectAtIndex:1];
    GNumberObject *widthObj = [[mediaBox value] objectAtIndex:2];
    GNumberObject *heightObj = [[mediaBox value] objectAtIndex:3];
//    CGFloat x = [xObj getRealValue];
//    CGFloat y = [yObj getRealValue];
    CGFloat w = [widthObj getRealValue];
    CGFloat h = [heightObj getRealValue];
//    NSRect mediaBoxRect = NSMakeRect(x, y, w, h);
//    NSLog(@"Page media box: %@", NSStringFromRect(mediaBoxRect));
    NSRect bounds = [doc bounds];
    CGFloat pageX = NSMidX(bounds) - (w / 2);
    CGFloat pageY = kPageMargin;
    CGFloat pageWidth = w;
    CGFloat pageHeight = h;
    NSRect pageRectFlipped = NSMakeRect(pageX, pageY, pageWidth, pageHeight);
    NSRect pageRect = [doc rectFromFlipped:pageRectFlipped];
    //NSLog(@"page rect: %@", NSStringFromRect(pageRect));
    return pageRect;
}

- (GFont*)getFontByName:(NSString*)name {
    GFont *f = [GFont fontWithName:name page:self];
    return f;
}

- (NSFont*)getCurrentFont:(NSString*)s {
    NSFont *f;
    NSString *fontName = [[self textState] fontName];
    CGFloat fontSize = [[self textState] fontSize];
    NSString *fontKey = [NSString stringWithFormat:@"%@-%f", fontName, fontSize];
    f = [self.cachedFonts objectForKey:fontKey];
    return f;
}

- (NSFont*)getFontByName:(NSString*)name size:(CGFloat)size {
    GFont *font = [self getFontByName:name];
    return [font getNSFontBySize:size];
}

- (GGraphicsState*)graphicsState {
    return graphicsState;
}

- (GTextState*)textState {
    return textState;
}

- (GTextParser*)textParser {
    return textParser;
}

- (void)keyDown:(NSEvent*)event {
    if (textEditor) {
        [textEditor keyDown:event];
    }
}

- (void)mouseDown:(NSEvent*)event {
    if (textEditor) {
        [textEditor mouseDown:event];
    }
    
    GTextBlock *last  = [[textParser makeTextBlocks] lastObject];
    textEditor = [GTextEditor textEditorWithPage:self textBlock:last];
    
    [self redraw];
}

- (void)mouseMoved:(NSEvent*)event {
    NSPoint location = [event locationInWindow];
    NSPoint point = [self.doc convertPoint:location fromView:nil];
    NSArray *blocks = [[self textParser] makeTextBlocks];
    highlightBlockFrame = NSZeroRect;
    for (GTextBlock *tb in blocks) {
        NSRect frame = [tb frame];
        NSRect viewFrame = [self rectFromPageToView:frame];
        if (NSPointInRect(point, viewFrame)) {
            highlightBlockFrame = frame;
            break;
        }
    }
    [self redraw];
}

- (NSRect)rectFromPageToView:(NSRect)rect {
    NSPoint o = [self origin];
    return NSMakeRect(rect.origin.x + o.x, rect.origin.y + o.y,
                      rect.size.width, rect.size.height);
}

- (void)buildPageContent {
    NSMutableString *ret = [NSMutableString string];
    
    // q Q q
    [ret appendString:@" q Q q "];

    int i;
    for (i = 0; i < [[textParser glyphs] count]; i++) {
        GGlyph *g = [[textParser glyphs] objectAtIndex:i];
        [ret appendString:[g complieToOperators]];
    }
    
    // Q
    // TODO: Fix context origin restore to (bottom, left) that causes
    //       text block frame not drawn at the right position, due to
    //       two Q (Q Q)
    [ret appendString:@"Q\n"];
    pageContent = (NSMutableData*)[ret dataUsingEncoding:NSASCIIStringEncoding];
}

- (void)redraw {
    [[self doc] setNeedsDisplay:YES];
}

- (void)initCommands {
    commands = [NSMutableArray array];
}

- (NSMutableArray *)commands {
    return commands;
}

- (void)initGlyphsForFontDict {
    self.glyphsForFontDict = [NSMutableDictionary dictionary];
}

- (void)addGlyph:(NSString*)glyphChar font:(NSString*)keyFontName {
    NSMutableSet *set = [self.glyphsForFontDict objectForKey:keyFontName];
    if (set == nil) {
        set = [NSMutableSet set];
        [set addObject:glyphChar];
        [self.glyphsForFontDict setObject:set forKey:keyFontName];
    } else {
        [set addObject:glyphChar];
    }
}

#pragma mark Adding stuff as GBinaryData to page
- (void)addFont:(NSFont*)font withPDFFontName:(NSString*)fontKey {
    GDictionaryObject *fontDict = [[resources value] objectForKey:@"Font"];
    GRefObject *fontRef = [[fontDict value] objectForKey:fontKey];
    GDictionaryObject *fontObject = [self.parser getObjectByRef:[fontRef getRefString]];
    GRefObject *fontDescriptorRef = [[fontObject value] objectForKey:@"FontDescriptor"];
    GDictionaryObject *fontDescriptor = [self.parser getObjectByRef:[fontDescriptorRef getRefString]];
    
    // TODO: Key "FontFile2" is not always the right key, we should handle other font file keys later
    GRefObject *fontFileRef = [[fontDescriptor value] objectForKey:@"FontFile2"];
    int objectNumber = [fontFileRef objectNumber];
    int generationNumber = [fontFileRef generationNumber];
        
    CGFontRef cgFont = CTFontCopyGraphicsFont((CTFontRef)font, nil);
    NSData *fontData = fontDataForCGFont(cgFont);
    
    NSData *encodedFontData = encodeFlate(fontData);
    
    int length = (int)[encodedFontData length];
    
    NSString *header = [NSString stringWithFormat:@"<< /Length %d /Length1 %d /Filter /FlateDecode >>\nstream\n",
                        length, length];
    NSMutableData *stream = [NSMutableData data];
    [stream appendData:[header dataUsingEncoding:NSASCIIStringEncoding]];
    [stream appendData:encodedFontData];
    NSString *end = @"\nendstream\n";
    [stream appendData:[end dataUsingEncoding:NSASCIIStringEncoding]];

    // Create a instance of GBinaryData
    GBinaryData *binary = [GBinaryData create];
    [binary setObjectNumber:objectNumber];
    [binary setGenerationNumber:generationNumber];
    [binary setData:stream];
    
    [self.dataToUpdate addObject:binary];
}

- (void)addPageStream {
    id contents = [[pageDictionary value] objectForKey:@"Contents"];
    int objectNumber = 0, generationNumber = 0;
    if ([(GObject*)contents type] == kRefObject) { // contents is a ref object
        GRefObject *contentRef = (GRefObject*)contents;
        objectNumber = [contentRef objectNumber];
        generationNumber = [contentRef generationNumber];
    } else { // contents is a GArrayObject, TODO: handle this later
        
    }
    
    NSData *encodedFontData = encodeFlate(pageContent);
    int length = (int)[encodedFontData length];
    NSMutableData *stream = [NSMutableData data];
    NSString *header = [NSString stringWithFormat:@"<< /Length %d /Filter /FlateDecode >>\nstream\n", length];
    [stream appendData:[header dataUsingEncoding:NSASCIIStringEncoding]];
    [stream appendData:encodedFontData];
    NSString *end = @"\nendstream\n";
    [stream appendData:[end dataUsingEncoding:NSASCIIStringEncoding]];
    
    // Create a instance of GBinaryData
    GBinaryData *binary = [GBinaryData create];
    [binary setObjectNumber:objectNumber];
    [binary setGenerationNumber:generationNumber];
    [binary setData:stream];
    
    [self.dataToUpdate addObject:binary];
}

- (NSData*)buildNewXRefTable {
    self.dataToUpdate = sortedGBinaryDataArray(self.dataToUpdate);
    NSMutableString *xrefTable = [NSMutableString string];
    NSMutableString *subTable = [NSMutableString string];
    [xrefTable appendString:@"xref\r\n"];
    int len = (int)[self.dataToUpdate count];
    GBinaryData *firstEntry = [self.dataToUpdate firstObject];
    int startIndex = [firstEntry objectNumber];
    int objectNumber = [firstEntry objectNumber];
    
    NSString *entry = buildXRefEntry([firstEntry offset], [firstEntry generationNumber], @"n");
    [subTable appendFormat:@"%@", entry];
    
    int count = 1;
    int i;
    for (i = 1; i < len; i++) {
        GBinaryData *b = [self.dataToUpdate objectAtIndex:i];
        if ([b objectNumber] == objectNumber + 1) {
            NSString *entry = buildXRefEntry([b offset], [b generationNumber], @"n");
            [subTable appendFormat:@"%@", entry];
            objectNumber = [b objectNumber];
            count++;
            
            // Handle edge case when current entry is last entry, and object number
            // is one bigger than previous entry
            if (i == len - 1) {
                NSString *subTableHeader = [NSString stringWithFormat:@"%d %d\r\n",
                                            startIndex, count];
                [xrefTable appendString:subTableHeader];
                [xrefTable appendString:subTable];
            }
        } else { // Add sub table
            NSString *subTableHeader = [NSString stringWithFormat:@"%d %d\r\n",
                                        startIndex, count];
            [xrefTable appendString:subTableHeader];
            [xrefTable appendString:subTable];
            
            // We have other sub tables, start new sub table
            if (i + 1 < len && i != len - 1) {
                GBinaryData *next = [self.dataToUpdate objectAtIndex:i+1];
                startIndex = [next objectNumber];
                count = 1;
                objectNumber = [next objectNumber];
                subTable = [NSMutableString string];
            }
            
            // Handle edge case when current entry is last entry
            if (i == len - 1) {
                startIndex = [b objectNumber];
                count = 1;
                NSMutableString *subTable = [NSMutableString string];
                NSString *entry = buildXRefEntry([b offset], [b generationNumber], @"n");
                [subTable appendFormat:@"%@", entry];
                NSString *subTableHeader = [NSString stringWithFormat:@"%d %d\r\n",
                                            startIndex, count];
                [xrefTable appendString:subTableHeader];
                [xrefTable appendString:subTable];
            }
        }
    }
    return [xrefTable dataUsingEncoding:NSASCIIStringEncoding];
}

- (NSData*)buildNewTrailer:(GDictionaryObject*)trailerDict
             prevStartXRef:(int)prevStartXRef
              newStartXRef:(int)newStartXRef {
    NSMutableString *ret = [NSMutableString string];
    [ret appendString:@"trailer\r\n"];
    
    // Add "\Prev" key
    GNumberObject *prev = [[trailerDict value] objectForKey:@"Prev"];
    if (!prev) {
        GNumberObject *addedPrev = [GNumberObject create];
        NSString *s = [NSString stringWithFormat:@"%d", prevStartXRef];
        [addedPrev setType:kNumberObject];
        [addedPrev setRawContent:[s dataUsingEncoding:NSASCIIStringEncoding]];
        [addedPrev parse];
        [[trailerDict value] setObject:addedPrev forKey:@"Prev"];
    } else {
        // NOTE: Check if it works as expected later
        [prev setIntValue:prevStartXRef];
    }
    [ret appendString:[trailerDict toString]];
    NSString *startXRef = [NSString stringWithFormat:@"\r\nstartxref\r\n%d\r\n%%EOF\r\n", newStartXRef];
    [ret appendString:startXRef];
    return [ret dataUsingEncoding:NSASCIIStringEncoding];
}

- (void)incrementalUpdate {
    NSMutableData *stream = [self.parser stream];
    // remove last added content from stream
    [stream setLength:self.lastStreamOffset];
    
    int prevStartXRef = [[self parser] getStartXRef];
    GDictionaryObject *trailerDict = [[self parser] getTrailer];

    // Append GBinaryData array data into parser/lexer stream
    int i;
    for (i = 0; i < [self.dataToUpdate count]; i++) {
        int offset = (int)[stream length];
        GBinaryData *b = [self.dataToUpdate objectAtIndex:i];
        [b setOffset:offset];
        NSData *d = [b getDataAsIndirectObject];
        [stream appendData:d];
    }
    
    // Append XRef table
    int startXRef = (int)[stream length];
    NSData *data = [self buildNewXRefTable];
    [stream appendData:data];
    
    data = [self buildNewTrailer:trailerDict
                   prevStartXRef:prevStartXRef
                    newStartXRef:startXRef];
    
    [stream appendData:data];
    [self.dataToUpdate removeAllObjects];
}

- (void)setCachedFont:(NSString*)fontName fontSize:(CGFloat)fontSize {
    NSString *fontKey = [NSString stringWithFormat:@"%@-%f", fontName, fontSize];
    NSFont *existFont = [self.cachedFonts objectForKey:fontKey];
    if (existFont) return ;
    GFont *font = [GFont fontWithName:fontName page:self];
    NSFont *f = [font getNSFontBySize:fontSize];
    
    [self.cachedFonts setObject:f forKey:fontKey];
}

- (void)buildCachedFonts {
    [self.cachedFonts removeAllObjects];
    NSMutableArray *commands = [self commands];
    NSUInteger i;
    for (i = 0; i < [commands count]; i++) {
        id obj = [commands objectAtIndex:i];
        if ([(GObject*) obj type] == kCommandObject) {
            GCommandObject *cmdObj = (GCommandObject*)obj;
            NSString *cmd = [cmdObj cmd];
            if (isCommand(cmd, @"Tf")) { // eval Tf
                NSString *fontName = [(GNameObject*)[[cmdObj args] objectAtIndex:0] value];
                CGFloat fontSize = [[[cmdObj args] objectAtIndex:1] getRealValue];
                [self setCachedFont:fontName fontSize:fontSize];
            }
        }
    }
}
@end
