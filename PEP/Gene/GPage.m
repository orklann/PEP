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
#import "GCompiler.h"
#import "GBinaryData.h"

@implementation GPage

+ (id)create {
    GPage *p = [[GPage alloc] init];
    [p setNeedUpdate:YES];
    p.dataToUpdate = [NSMutableArray array];
    p.cachedFonts = [NSMutableDictionary dictionary];
    p.addedFonts = [NSMutableDictionary dictionary];
    p.isRendering = NO;
    p.pageYOffsetInDoc = 0.0;
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
    id content = [[pageDictionary value] objectForKey:@"Contents"];
    if ([(GObject*)content type] == kArrayObject) {
        GArrayObject *contentArray = (GArrayObject*)content;
        pageContent = [NSMutableData data];
        for (GRefObject *ref in [contentArray value]) {
            GStreamObject *contentStream = [parser getObjectByRef:[ref getRefString]];
            NSMutableData* data = (NSMutableData*)[contentStream getDecodedStreamContent];
            [pageContent appendData:data];
            [pageContent appendBytes:@"\n" length:1];
        }
    } else if ([(GObject*)content type] == kRefObject) {
        GRefObject *ref = (GRefObject*)content;
        GStreamObject *contentStream = [parser getObjectByRef:[ref getRefString]];
        pageContent = (NSMutableData*)[contentStream getDecodedStreamContent];
    }
    
    printData(pageContent);
    
    // Automatically parse resources
    [self parseResources];
}

- (void)parseResources {
    id res = [[pageDictionary value] objectForKey:@"Resources"];
    if ([(GObject*)res type] == kRefObject) {
        GRefObject *ref = (GRefObject*)res;
        resources = [parser getObjectByRef:[ref getRefString]];
    } else if ([(GObject*)res type] == kDictionaryObject)  {
        resources = (GDictionaryObject*)res;
    }
}

- (GDictionaryObject*)resources {
    return resources;
}

- (void)translateToPageOrigin:(CGContextRef)context {
    CGFloat offsetX = 0.0;
    CGFloat offsetY = 0.0;
    if ([[self.doc pages] indexOfObject:self] == 0) {
        NSPoint origin = [self origin];
        offsetX = origin.x;
        offsetY = origin.y;
    } else {
        offsetX = 0;
        NSRect pageRect = [self calculatePageMediaBox];
        offsetY = pageRect.size.height + kPageMargin;
        offsetY *= -1;
    }
    NSPoint o = NSMakePoint(offsetX, offsetY);
    CGContextTranslateCTM(context, o.x, o.y);
}

- (void)render:(CGContextRef)context {
    if (self.isRendering) {
        return ;
    }
    self.isRendering = YES;
    if (self.needUpdate) {
        [self initGlyphsForFontDict];
    }
    
    // Translate context origin to page media box origin
    [self translateToPageOrigin:context];
    
    // Draw media box (a.k.a page boundary)
    NSRect pageRect = [self calculatePageMediaBox];
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    // Make origin of page rect to zero point,
    // because we translated the origin of context to page rect above
    pageRect.origin.y = 0;
    pageRect.origin.x = 0;
    CGContextFillRect(context, pageRect);
    
    textState = [GTextState create];
    graphicsState = [GGraphicsState create];
    graphicsStateStack = [NSMutableArray array];
    
    if (self.needUpdate) {
        textParser = [GTextParser create];
    }
        
    GInterpreter *interpreter = [GInterpreter create];
    [interpreter setPage:self];
    [interpreter setParser:parser];
    [interpreter setInput:pageContent];
    
    //NSDate *methodStart = [NSDate date];
    [interpreter eval:context];
    
    /* Measrure time */
    /*
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"Debug: render() executionTime = %f", executionTime);
    */
    
    GTextEditor *textEditor = [self.doc textEditor];
    if (textEditor != nil && [textEditor editorInPage] == self) {
        [textEditor draw:context];
    }
    
    // If context's origin is (0, 0), we need to add translate to page's origin
    // which is not (x, y), because highlightBlockFrame is in page coordinate
    CGAffineTransform ctm = CGContextGetCTM(context);
    if (ctm.tx == 0.0 && ctm.ty == 0.0) {
        highlightBlockFrame = [self rectFromPageToView:highlightBlockFrame];
    }
    
    // Draw highlith text block border
    CGContextSetLineWidth(context, 1.0 / (kScaleFactor));
    CGContextSetRGBStrokeColor(context, 0.22, 0.66, 0.99, 1.0);
    CGContextStrokeRect(context, highlightBlockFrame);
    
    [self setNeedUpdate:NO];
    self.isRendering = NO;
    
    /* Test: draw glyph bounding box */
    /* for (GGlyph * g in [textParser glyphs]) {
        NSRect r = [g frame];
        CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 0.5);
        CGContextFillRect(context, r);
    }*/
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
    CGFloat pageY = kPageMargin + self.pageYOffsetInDoc;
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
    // [[self textState] fontSize] used in text matrix,
    // So we only need font size to be 1.0 for actuall NSFont;
    CGFloat fontSize = 1.0f; //[[self textState] fontSize];
    NSString *fontKey = [NSString stringWithFormat:@"%@-%f", fontName, fontSize];
    f = [self.addedFonts objectForKey:fontKey];
    if (f) {
        return f;
    }
    f = [self.cachedFonts objectForKey:fontKey];
    return f;
}

- (NSFont*)getCachedFontForKey:(NSString*)key {
    NSFont *font;
    font = [self.addedFonts objectForKey:key];
    if (font){
        return font;
    }
    return [self.cachedFonts objectForKey:key];
}

- (NSFont*)getCachedFontByFontTag:(NSString*)fontTag {
    CGFloat fontSize = 1.0f;
    NSString *fontKey = [NSString stringWithFormat:@"%@-%f", fontTag, fontSize];
    return [self getCachedFontForKey:fontKey];
}

- (NSFont*)getFontByName:(NSString*)name size:(CGFloat)size {
    GFont *font = [self getFontByName:name];
    return [font getNSFontBySize:size];
}

- (NSString*)getFontNameByFontTag:(NSString*)fontTag {
    GDictionaryObject *fontDict = [[resources value] objectForKey:@"Font"];
    if ([(GObject*)fontDict type] == kRefObject) {
        fontDict = [self.parser getObjectByRef:[(GRefObject*)fontDict getRefString]];
    } 
    GRefObject *fontRef = [[fontDict value] objectForKey:fontTag];
    GDictionaryObject *fontObject = [self.parser getObjectByRef:[fontRef getRefString]];
    GLiteralStringsObject *fontName = [[fontObject value] objectForKey:@"BaseFont"];
    return [fontName value];
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
    if ([doc textEditor]) {
        [[doc textEditor] keyDown:event];
    }
    
    /*
    [self buildPageContent];
    [self setNeedUpdate:YES];
    [self redraw];
    */
}

- (void)mouseDown:(NSEvent*)event {
    if ([doc mode] != kTextEditMode) {
        return ;
    }
    NSPoint location = [event locationInWindow];
    NSPoint point = [self.doc convertPoint:location fromView:nil];
    
    GTextEditor *textEditor = [doc textEditor];
    
    if (textEditor) {
        [textEditor mouseDown:event];
        NSRect frame = [textEditor frame];
        NSRect viewFrame = [self rectFromPageToView:frame];
        if (!NSPointInRect(point, viewFrame) && [textEditor editorInPage] == self) {
           [doc setTextEditor:nil];
        }
        [self redraw];
    }
    
    if ([doc textEditor]) {
        return ;
    }
    
    NSArray *blocks = [[self textParser] makeTextBlocks];
    highlightBlockFrame = NSZeroRect;
    for (GTextBlock *tb in blocks) {
        NSRect frame = [tb frame];
        NSRect viewFrame = [self rectFromPageToView:frame];
        if (NSPointInRect(point, viewFrame)) {
            GTextEditor *textEditor = [GTextEditor textEditorWithPage:self textBlock:tb];
            [textEditor setEditorInPage:self];
            unsigned int index = (unsigned int)[blocks indexOfObject:tb];
            [textEditor setTextBlockIndex:index];
            [doc setTextEditor:textEditor];
            [self redraw];
            return ;
        }
    }
}

- (void)mouseMoved:(NSEvent*)event {
    if ([doc mode] != kTextEditMode) {
        return ;
    }
    
    
    if ([doc textEditor]) {
        [self redraw];
        return ;
    }
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

- (NSPoint)pointFromPageToView:(NSPoint)p {
    NSPoint o = [self origin];
    return NSMakePoint(p.x + o.x, p.y + o.y);
}

- (void)buildPageContent {
    [[self textParser] setCached:NO];
    [[self textParser] makeReadOrderGlyphs];
    GCompiler *comp = [GCompiler compilerWithPage:self];
    NSString *result = [comp compile];
    // Note: use "allowLossyConversion:YES" to prevent 0 length page content.
    //       If use UTF8 encoding, the result is wrong with Unicode random characters
    pageContent = (NSMutableData*)[result dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    printData(pageContent);
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
- (NSString*)addFont:(NSFont*)font withPDFFontName:(NSString*)fontKey {
    /*
     * 1. Generate font file stream
     */
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
    NSString *fontFileRef = [doc generateNewRef];
    int fontFileObjectNumber = getObjectNumber(fontFileRef);
    int fontFileGenerationNumber = getGenerationNumber(fontFileRef);
    
    GBinaryData *binary = [GBinaryData create];
    [binary setObjectNumber:fontFileObjectNumber];
    [binary setGenerationNumber:fontFileGenerationNumber];
    [binary setData:stream];
    [self.dataToUpdate addObject:binary];
    
    /*
     * 2. Generate font descriptor dictionary
     */
    
    // "/Flags 32" make Adobe Acrobat render new text with new font
    header = [NSString stringWithFormat:@"<< /Type /FontDescriptor /FontName /%@ /FontFile2 %d %d R /Flags 32 >>\n",
              [font fontName], fontFileObjectNumber, fontFileGenerationNumber];
    
    stream = [NSMutableData data];
    [stream appendData:[header dataUsingEncoding:NSASCIIStringEncoding]];
    
    NSString *descriptorRef = [doc generateNewRef];
    int descriptorObjectNumber = getObjectNumber(descriptorRef);
    int descriptorGenerationNumber = getGenerationNumber(descriptorRef);
    
    binary = [GBinaryData create];
    [binary setObjectNumber:descriptorObjectNumber];
    [binary setGenerationNumber:descriptorGenerationNumber];
    [binary setData:stream];
    [self.dataToUpdate addObject:binary];
    
    /*
     * 3. Generate font dictionary
     */
    header = [NSString stringWithFormat:@"<< /Type /Font /Subtype /TrueType /BaseFont /%@ /FontDescriptor %d %d R /Encoding /MacRomanEncoding >>\n", [font fontName], descriptorObjectNumber, descriptorGenerationNumber];
    
    stream = [NSMutableData data];
    [stream appendData:[header dataUsingEncoding:NSASCIIStringEncoding]];
    
    NSString *fontRef = [doc generateNewRef];
    int fontObjectNumber = getObjectNumber(fontRef);
    int fontGenerationNumber = getGenerationNumber(fontRef);
    
    binary = [GBinaryData create];
    [binary setObjectNumber:fontObjectNumber];
    [binary setGenerationNumber:fontGenerationNumber];
    [binary setData:stream];
    [self.dataToUpdate addObject:binary];
    
    return fontRef;
}

- (void)addNewAddedFontsForUpdating {
    int resourcesObjectNumber = 0, resourcesGenerationNumber = 0;
    id res = [[pageDictionary value] objectForKey:@"Resources"];
    if ([(GObject*)res type] == kRefObject) {
        GRefObject *ref = (GRefObject*)res;
        resourcesObjectNumber = [ref objectNumber];
        resourcesGenerationNumber = [ref generationNumber];
    } else if ([(GObject*)res type] == kDictionaryObject){
        // TODO: Should also handle the case if resources is a dictionary in page dictionary
        NSLog(@"[Error: Not Handled] Resources is a dictionary in page dictionary, not an indirect object");
    }
    
    NSMutableString *fontArrayString = [NSMutableString string];
    
    // Initialize fontArrayString with original font arrays
    GDictionaryObject *fontArray = [[resources value] objectForKey:@"Font"];
    for (NSString *fontName in [fontArray value]) {
        // NOTE: Because we add new font if selected font is the same as original PDF font, so we should overwrite origin
        // font tag, so that we remove original font tag, if it's in added fonts
        if ([self isFontTagInAddedFonts:fontName]) {
            continue;
        }
        GRefObject *ref = [[fontArray value] objectForKey:fontName];
        int objectNumber = [ref objectNumber];
        int generationNumber = [ref generationNumber];
        [fontArrayString appendFormat:@"/%@ %d %d R ", fontName, objectNumber, generationNumber];
    }
    
    // Append new created font and ref to fontArrayString
    for (NSString *pdfFontKey in self.addedFonts) {
        NSFont *font = [self.addedFonts objectForKey:pdfFontKey];
        NSString *realFontKey = [[pdfFontKey componentsSeparatedByString:@"-"] firstObject];
        NSString *fontRef = [self addFont:font withPDFFontName:realFontKey];
        int objectNumber = getObjectNumber(fontRef);
        int generationNumber = getGenerationNumber(fontRef);
        [fontArrayString appendFormat:@"/%@ %d %d R ", realFontKey, objectNumber, generationNumber];
    }
    
    // TODO: Add /ColorSpace, /ExtGState (No Need if we have below TODO)
    // TODO: Better to reuse original resource which has /ColorSpace, /ExtGState, and other settings
    NSString *dictionary = [NSString stringWithFormat:@"<< /ProcSet [ /PDF /Text ] /Font << %@ >> >>\n", fontArrayString];
    
    NSMutableData *stream = [NSMutableData data];
    [stream appendData:[dictionary dataUsingEncoding:NSASCIIStringEncoding]];;

    // Create a instance of GBinaryData
    GBinaryData *binary = [GBinaryData create];
    [binary setObjectNumber:resourcesObjectNumber];
    [binary setGenerationNumber:resourcesGenerationNumber];
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
    NSMutableArray *groups = groupingGBinaryDataArray(self.dataToUpdate);
    NSMutableString *xrefTable = [NSMutableString string];
    [xrefTable appendString:@"xref\r\n"];
    
    for (NSMutableArray *group in groups) {
        NSMutableString *groupTable = [NSMutableString string];
        GBinaryData *firstBinaryData = [group firstObject];
        [groupTable appendFormat:@"%d %d\r\n", [firstBinaryData objectNumber], (int)[group count]];
        for (GBinaryData *binaryData in group) {
            NSString *entry = buildXRefEntry([binaryData offset], [binaryData generationNumber], @"n");
            [groupTable appendString:entry];
        }
        [xrefTable appendString:groupTable];
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
    NSLog(@"Debug incremental update");
    // Build page content, and add it to "dataToUpdate" array
    [self buildPageContent];
    [self addPageStream];
    [self addNewAddedFontsForUpdating];
    
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
                // [[self textState] fontSize] (set by Tj operator) used in text matrix,
                // So we only need font size to be 1.0 for actuall NSFont;
                CGFloat fontSize = 1.0f; //[[[cmdObj args] objectAtIndex:1] getRealValue];
                [self setCachedFont:fontName fontSize:fontSize];
            }
        }
    }
}

- (void)addNewFont:(NSFont*)font withPDFFontTag:(NSString*)fontTag {
    CGFloat fontSize = 1.0f;
    NSString *fontKey = [NSString stringWithFormat:@"%@-%f", fontTag, fontSize];
    [self.addedFonts setObject:font forKey:fontKey];
}

- (void)saveGraphicsState {
    [graphicsStateStack addObject:[graphicsState clone]];
}

- (void)restoreGraphicsState {
    GGraphicsState *lastObject = [graphicsStateStack lastObject];
    graphicsState = lastObject;
    [graphicsStateStack removeObject:lastObject];
}

- (NSArray *)getFontTags {
    GDictionaryObject *fontDict = [[resources value] objectForKey:@"Font"];
    if ([(GObject*)fontDict type] == kRefObject) {
        fontDict = [self.parser getObjectByRef:[(GRefObject*)fontDict getRefString]];
    }
    return [[fontDict value] allKeys];
}

- (NSArray *)getNewAddedTags {
    NSArray *newAddedTags = [self.addedFonts allKeys];
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *key in newAddedTags) {
        NSString *tag = [[key componentsSeparatedByString:@"-"] firstObject];
        [result addObject:tag];
    }
    return result;
}

- (NSString*)generateNewPDFFontTag {
    int i = 1;
    NSString *fontTag = [NSString stringWithFormat:@"Font%d", i];
    NSArray *tags = [self getFontTags];
    NSArray *newAddedTags = [self getNewAddedTags];
    while ([tags containsObject:fontTag] || [newAddedTags containsObject:fontTag]) {
        i += 1;
        fontTag = [NSString stringWithFormat:@"Font%d", i];
    }
    return fontTag;
}

- (BOOL)isFontTagInAddedFonts:(NSString*)fontTag {
    for (NSString *key in self.addedFonts) {
        NSString *tag = [[key componentsSeparatedByString:@"-"] firstObject];
        if ([fontTag isEqualToString:tag]) {
            return YES;
        }
    }
    return NO;
}
@end
