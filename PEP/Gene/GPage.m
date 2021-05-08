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
#import "GFontInfo.h"
#import "GFontEncoding.h"

@implementation GPage

+ (id)create {
    GPage *p = [[GPage alloc] init];
    [p setNeedUpdate:YES];
    p.addedFonts = [NSMutableDictionary dictionary];
    p.isRendering = NO;
    p.pageYOffsetInDoc = 0.0;
    p.dirty = NO;
    p.fontKeysDict = [NSMutableDictionary dictionary];
    p.prewarm = NO;
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

/*
 * Prewarm to create all data needed to render later without drawing anything
 */
- (void)prewarmRender {
    if (self.needUpdate) {
        [self initGlyphsForFontDict];
    } else {
        return ;
    }
    
    if (self.prewarm) {
        return ;
    }
    
    self.prewarm = YES;
    
    textState = [GTextState create];
    graphicsState = [GGraphicsState create];
    graphicsStateStack = [NSMutableArray array];
    
    if (self.needUpdate) {
        textParser = [GTextParser create];
        _graphicElements = [NSMutableArray array];
    }
    
    /*
     * Faked context, we don't draw anthing onto this context
     */
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    _interpreter = [GInterpreter create];
    [_interpreter setPage:self];
    [_interpreter setParser:parser];
    [_interpreter setInput:pageContent];
    
    [_interpreter eval:context];
    [self setPrewarm:NO];
    [self setNeedUpdate:NO];
}


- (void)render:(CGContextRef)context {
    if (self.isRendering) {
        return ;
    }
    
    if (self.prewarm) {
        return ;
    }
    
    self.isRendering = YES;
    if (self.needUpdate) {
        [self initGlyphsForFontDict];
    }
    
    
    // Translate context origin to page media box origin
    [self translateToPageOrigin:context];
    
    NSRect pageRect = [self calculatePageMediaBox];
    
    NSRect backgroundRect = NSMakeRect(-1 * pageRect.origin.x, -1 * kPageMargin, [doc bounds].size.width, pageRect.size.height + (kPageMargin*2));
    CGContextSetRGBFillColor(context, 0.93, 0.93, 0.93, 1.0);
    CGContextFillRect(context, backgroundRect);
    
    // Draw media box (a.k.a page boundary)
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    // Make origin of page rect to zero point,
    // because we translated the origin of context to page rect above
    pageRect.origin.y = 0;
    pageRect.origin.x = 0;
    NSLog(@"page rect: %@", NSStringFromRect(pageRect));
    CGContextFillRect(context, pageRect);
    
    textState = [GTextState create];
    graphicsState = [GGraphicsState create];
    graphicsStateStack = [NSMutableArray array];
    
    if (self.needUpdate) {
        textParser = [GTextParser create];
        _graphicElements = [NSMutableArray array];
    }
    
    // Apply CropBox origin shifting
    // Shift left, down by CropBox's x and y, because now the origin is
    // At origin of CropBox (We made this in calcuatePageMediaBox)
    NSRect cropBox = [self getPageCropBox];
    if (!NSEqualRects(cropBox, NSZeroRect)) {
        CGFloat deltaX = cropBox.origin.x * -1;
        CGFloat deltaY = cropBox.origin.y * -1;
        /* #1: Save graphic state to keep later pages CTM correct, restore at #2 below */
        CGContextSaveGState(context);
        
        /* The shifting happens here */
        CGContextTranslateCTM(context, deltaX, deltaY);
        
        /* Clip by using CropBox */
        CGContextClipToRect(context, cropBox);
    }
    
    _interpreter = [GInterpreter create];
    [_interpreter setPage:self];
    [_interpreter setParser:parser];
    [_interpreter setInput:pageContent];
    
    //NSDate *methodStart = [NSDate date];
    [_interpreter eval:context];
    
    /* Measrure time */
    /*
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"Debug: render() executionTime = %f", executionTime);
    */
    
    if (!NSEqualRects(cropBox, NSZeroRect)) {
        /* #2: Restore for #1 above to keep later pages CTM correct*/
        CGContextRestoreGState(context);
    }
    
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
    /*for (GGlyph * g in [textParser glyphs]) {
        NSRect r = [g frame];
        CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 0.5);
        CGContextFillRect(context, r);
    }*/
    
    /* Test word distance
    for (GWord *w in [textParser words]) {
        CGFloat wordDistance = [w wordDistance];
        if (wordDistance != 0 && wordDistance != kNoWordDistance) {
            NSRect r = [w frame];
            CGAffineTransform ctm = [[[w glyphs] firstObject] ctm];
            NSSize s = NSMakeSize(wordDistance, 0);
            s = CGSizeApplyAffineTransform(s, ctm);
            r.origin.x -= s.width;
            r.size.width = s.width;
            CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 0.5);
            CGContextFillRect(context, r);
        }
    }
    */
}

// Calculate media box for PDF page in user space coordinate
// Return rect with origin in bottom left
- (NSRect)calculatePageMediaBox {
    GArrayObject *mediaBox = [[pageDictionary value] objectForKey:@"MediaBox"];
    NSRect cropBox = [self getPageCropBox];
    GNumberObject *widthObj = [[mediaBox value] objectAtIndex:2];
    GNumberObject *heightObj = [[mediaBox value] objectAtIndex:3];
    
    // NOTE: Calculation of w, h is not the same as CropBox, since MediaBox's x, y is alwasy 0.
    CGFloat w = [widthObj getRealValue];
    CGFloat h = [heightObj getRealValue];
    
    // NSZeroRect returned means no /CropBox key in page
    if (!NSEqualRects(cropBox, NSZeroRect)) {
        w = cropBox.size.width;
        h = cropBox.size.height;
    }
    
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

- (NSRect)getPageCropBox {
    NSRect cropRect = NSZeroRect;
    GArrayObject *cropBoxObject = [[pageDictionary value] objectForKey:@"CropBox"];
    if (cropBoxObject == nil) {
        return NSZeroRect;
    }
    
    GNumberObject *xObj = [[cropBoxObject value] objectAtIndex:0];
    GNumberObject *yObj = [[cropBoxObject value] objectAtIndex:1];
    GNumberObject *widthObj = [[cropBoxObject value] objectAtIndex:2];
    GNumberObject *heightObj = [[cropBoxObject value] objectAtIndex:3];
    
    CGFloat x = [xObj getRealValue];
    CGFloat y = [yObj getRealValue];
    CGFloat x2 = [widthObj getRealValue];
    CGFloat y2 = [heightObj getRealValue];
    
    CGFloat w = x2 - x;
    CGFloat h = y2 - y;
    cropRect = NSMakeRect(x, y, w, h);
    _cropBox = cropRect;
    return cropRect;
}

- (GFont*)getFontByName:(NSString*)name {
    GFont *f = [GFont fontWithName:name page:self];
    return f;
}

- (NSFont*)getCurrentFont:(NSString*)s {
    NSFont *f;
    NSString *fontName = [[self textState] fontName];
    NSString *fontKey = [self fontTagToFontKey:fontName];
    f = [self.addedFonts objectForKey:fontKey];
    if (f) {
        return f;
    }
    f = [[self cachedFonts] objectForKey:fontKey];
    return f;
}

- (NSFont*)getCachedFontForKey:(NSString*)key {
    NSFont *font;
    font = [self.addedFonts objectForKey:key];
    if (font){
        return font;
    }
    return [[self cachedFonts] objectForKey:key];
}

- (NSFont*)getCachedFontByFontTag:(NSString*)fontTag {
    NSString *fontKey = [self fontTagToFontKey:fontTag];
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
            [textEditor stopBlinkTimer];
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
    [[self doc] setNeedsDisplayInRect:[[self doc] visibleRect]];
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
    NSString *fontFileRef = [[fontKey componentsSeparatedByString:@"~"] lastObject];
    int fontFileObjectNumber = getObjectNumber(fontFileRef);
    int fontFileGenerationNumber = getGenerationNumber(fontFileRef);
    
    GBinaryData *binary = [GBinaryData create];
    [binary setObjectNumber:fontFileObjectNumber];
    [binary setGenerationNumber:fontFileGenerationNumber];
    [binary setData:stream];
    [doc.dataToUpdate addObject:binary];
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
    [doc.dataToUpdate addObject:binary];
    /*
     * 3. Generate font dictionary:
     */
    header = [NSString stringWithFormat:@"<< /Type /Font /Subtype /TrueType /BaseFont /%@ /FontDescriptor %d %d R /Encoding /MacRomanEncoding  >>\n", [font fontName], descriptorObjectNumber, descriptorGenerationNumber];
    
    stream = [NSMutableData data];
    [stream appendData:[header dataUsingEncoding:NSASCIIStringEncoding]];
    
    NSString *fontRef = [doc generateNewRef];
    int fontObjectNumber = getObjectNumber(fontRef);
    int fontGenerationNumber = getGenerationNumber(fontRef);
    
    binary = [GBinaryData create];
    [binary setObjectNumber:fontObjectNumber];
    [binary setGenerationNumber:fontGenerationNumber];
    [binary setData:stream];
    [doc.dataToUpdate addObject:binary];
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
        // We handle this case below: resources is a dictionary,
        // not an indrect object
        NSLog(@"(Handled) resources is a dictionary: %@", [(GDictionaryObject *)res toString]);
        resources = (GDictionaryObject*)res;
    }
    
    NSMutableString *fontArrayString = [NSMutableString string];
    
    // Initialize fontArrayString with original font arrays
    GDictionaryObject *fontArray;
    GObject *refObject = [[resources value] objectForKey:@"Font"];
    if ([refObject type] == kRefObject) {
        fontArray = [parser getObjectByRef:[(GRefObject*)refObject getRefString]];
    } else {
        fontArray = (GDictionaryObject*)refObject;
    }

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
        NSString *realFontKey = [[pdfFontKey componentsSeparatedByString:@"~"] firstObject];
        NSString *fontRef = [self addFont:font withPDFFontName:pdfFontKey];
        int objectNumber = getObjectNumber(fontRef);
        int generationNumber = getGenerationNumber(fontRef);
        [fontArrayString appendFormat:@"/%@ %d %d R ", realFontKey, objectNumber, generationNumber];
    }
    
    // TODO: Add /ColorSpace, /ExtGState (No Need if we have below TODO)
    // TODO: Better to reuse original resource which has /ColorSpace, /ExtGState, and other settings
    NSString *dictionary = [NSString stringWithFormat:@"<< /ProcSet [ /PDF /Text ] /Font << %@ >> >>\n", fontArrayString];
    
    //  Resources is a dictionary
    if ([(GObject*)res type] == kDictionaryObject){
        GParser *p = [GParser parser];
        [p setStream:[dictionary dataUsingEncoding:NSASCIIStringEncoding]];
        GDictionaryObject *dictionaryObject = [p parseNextObject];
        [[pageDictionary value] setObject:dictionaryObject forKey:@"Resources"];
    } else { // Resources is an indirect object
        NSMutableData *stream = [NSMutableData data];
        [stream appendData:[dictionary dataUsingEncoding:NSASCIIStringEncoding]];

        // Create a instance of GBinaryData
        GBinaryData *binary = [GBinaryData create];
        [binary setObjectNumber:resourcesObjectNumber];
        [binary setGenerationNumber:resourcesGenerationNumber];
        [binary setData:stream];
        
        [doc.dataToUpdate addObject:binary];
    }
    
    // Update resource by parsing it
    [self parseResources];
}

- (void)addPageDictionaryForUpdating {
    NSMutableData *stream = [NSMutableData data];
    [stream appendData:[[pageDictionary toString]
                        dataUsingEncoding:NSASCIIStringEncoding]];

    // Create a instance of GBinaryData
    GBinaryData *binary = [GBinaryData create];
    [binary setObjectNumber:[self.pageRef objectNumber]];
    [binary setGenerationNumber:[self.pageRef generationNumber]];
    [binary setData:stream];
    [doc.dataToUpdate addObject:binary];
}

- (void)addPageStream {
    id contents = [[pageDictionary value] objectForKey:@"Contents"];
    int objectNumber = 0, generationNumber = 0;
    if ([(GObject*)contents type] == kRefObject) { // contents is a ref object
        GRefObject *contentRef = (GRefObject*)contents;
        objectNumber = [contentRef objectNumber];
        generationNumber = [contentRef generationNumber];
    } else { // contents is a GArrayObject
        NSString *newContentRef = [doc generateNewRef];
        objectNumber = getObjectNumber(newContentRef);
        generationNumber = getGenerationNumber(newContentRef);
        
        // Also update "Contents" for pageDictionary
        GParser *p = [GParser parser];
        NSString *s = [NSString stringWithFormat:@"%d %d R ", objectNumber, generationNumber];
        [p setStream:[s dataUsingEncoding:NSASCIIStringEncoding]];
        GRefObject *refObject = [p parseNextObject];
        [[pageDictionary value] setObject:refObject forKey:@"Contents"];
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
    
    [doc.dataToUpdate addObject:binary];
}

- (void)incrementalUpdate {
    if (!self.dirty) return ;
    NSLog(@"GPage: Debug incremental update");
    // Build page content, and add it to "dataToUpdate" array
    [self buildPageContent];
    [self addPageStream];
    [self addNewAddedFontsForUpdating];
    [self addPageDictionaryForUpdating];
}

- (void)setCachedFont:(NSString*)fontName fontSize:(CGFloat)fontSize {
    //NSString *fontKey = [NSString stringWithFormat:@"%@-%f", fontName, fontSize];
    NSString *fontKey = [self fontTagToFontKey:fontName];
    NSFont *existFont = [[self cachedFonts] objectForKey:fontKey];
    if (existFont) return ;
    GFont *font = [GFont fontWithName:fontName page:self];
    NSFont *f = [font getNSFontBySize:fontSize];
    [[self cachedFonts] setObject:f forKey:fontKey];
}

- (void)buildCachedFonts {
    GDictionaryObject *fontDictionary;
    GObject *refObject = [[resources value] objectForKey:@"Font"];
    if ([refObject type] == kRefObject) {
        fontDictionary = [parser getObjectByRef:[(GRefObject*)refObject getRefString]];
    } else {
        fontDictionary = (GDictionaryObject*)refObject;
    }
    
    for (NSString *fontName in [[fontDictionary value] allKeys]) {
        // [[self textState] fontSize] (set by Tj operator) used in text matrix,
        // So we only need font size to be 1.0 for actuall NSFont;
        CGFloat fontSize = 1.0f;
        
        GRefObject *fontRef = [[fontDictionary value] objectForKey:fontName];
        NSString *fontKey = [NSString stringWithFormat:@"%@~%@", fontName, [fontRef getRefString]];
        [self.fontKeysDict setObject:fontKey forKey:fontName];
        [self setCachedFont:fontName fontSize:fontSize];
    }
}

// Just return document's cached fonts, it's now in document scope
- (NSMutableDictionary*)cachedFonts {
    return doc.cachedFonts;
}

- (void)addNewFont:(NSFont*)font withPDFFontTag:(NSString*)fontTag {
    NSString *refString = [doc generateNewRef];
    NSString *fontKey = [NSString stringWithFormat:@"%@~%@", fontTag, refString];
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
        NSString *tag = [[key componentsSeparatedByString:@"~"] firstObject];
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
        NSString *tag = [[key componentsSeparatedByString:@"~"] firstObject];
        if ([fontTag isEqualToString:tag]) {
            return YES;
        }
    }
    return NO;
}

- (void)buildFontEncodings {
    id fonts = [[resources value] objectForKey:@"Font"];
    if ([(GObject*)fonts type] == kRefObject) {
        fonts = [parser getObjectByRef:[fonts getRefString]];
    }
    
    GDictionaryObject *fontsDictionary = (GDictionaryObject*)fonts;
    for (NSString *fontTagKey in [[fontsDictionary value] allKeys]) {
        GRefObject *fontRef = [[fontsDictionary value] objectForKey:fontTagKey];
        GDictionaryObject *font = [parser getObjectByRef:[fontRef getRefString]];
        id encoding = [[font value] objectForKey:@"Encoding"];
        NSString *encodingString;
        GArrayObject *differencesArray;
        if ([(GObject*)encoding type] == kRefObject) {
            encoding = [parser getObjectByRef:[encoding getRefString]];
            if ([(GObject*)encoding type] == kDictionaryObject) {
                GDictionaryObject *encodingDictionary = (GDictionaryObject*)encoding;
                GNameObject *baseEncoding = [[encodingDictionary value] objectForKey:@"BaseEncoding"];
                encodingString = [baseEncoding value];
                
                // Difference array
                differencesArray = [[encodingDictionary value] objectForKey:@"Differences"];
            } else {
                NSLog(@"[Not implemented] in [GPage buildFontEncodings] while font (%@) encoding is a object of: %@",
                      fontTagKey, encoding);
            }
        } else if ([(GObject*)encoding type] == kNameObject) {
            encodingString = [(GNameObject*)encoding value];
        }
        
        
        GFontEncoding *fontEncoding = [GFontEncoding create];
        [fontEncoding setEncoding:encodingString];
        [fontEncoding parseDifference:differencesArray];
        
        NSString *fontKey = [self fontTagToFontKey:fontTagKey];
        if ([doc.fontEncodings objectForKey:fontKey] == nil) {
            [doc.fontEncodings setValue:fontEncoding forKey:fontKey];
        }
    }
    
}

- (void)buildFontInfos {
    // Debug:
    int index = (int)[doc.pages indexOfObject:self] + 1;
    NSLog(@"buildFontInfos for page: %d", index);
    id fonts = [[resources value] objectForKey:@"Font"];
    if ([(GObject*)fonts type] == kRefObject) {
        fonts = [parser getObjectByRef:[fonts getRefString]];
    }
    
    GDictionaryObject *fontsDictionary = (GDictionaryObject*)fonts;
    for (NSString *fontTagKey in [[fontsDictionary value] allKeys]) {
        GRefObject *fontRef = [[fontsDictionary value] objectForKey:fontTagKey];
        GDictionaryObject *font = [parser getObjectByRef:[fontRef getRefString]];
        
        GFontInfo *fontInfo = [GFontInfo create];
        GNumberObject *firstChar = [[font value] objectForKey:@"FirstChar"];
        GArrayObject *widthArray = [[font value] objectForKey:@"Widths"];
        GNameObject *subType = [[font value] objectForKey:@"Subtype"];
        
        [fontInfo setSubType:[subType value]];
        
        if (firstChar != nil) {
            [fontInfo setFirstChar:(int)[firstChar getRealValue]];
        }
        
        NSMutableArray *array = [NSMutableArray array];
        if (widthArray != nil) {
            if ([(GObject*)widthArray type] == kRefObject) {
                widthArray = [parser getObjectByRef:[(GRefObject*)widthArray getRefString]];
            }
            for (GNumberObject *v in [widthArray value]) {
                NSNumber *n = [NSNumber numberWithInt:(int)([v getRealValue])];
                [array addObject:n];
            }
        }
        [fontInfo setWidths:array];
        // Missing width in font descriptor
        GRefObject *fontDescriptorRef = [[font value] objectForKey:@"FontDescriptor"];
        if (fontDescriptorRef != nil) {
            GDictionaryObject *fontDescriptor = [parser getObjectByRef:[fontDescriptorRef getRefString]];
            GNumberObject *missingWidth = [[fontDescriptor value] objectForKey:@"MissingWidth"];
            [fontInfo setMissingWidth:(int)[missingWidth getRealValue]];
        }
        
        NSString *fontKey = [self fontTagToFontKey:fontTagKey];
        if ([doc.fontInfos objectForKey:fontKey] == nil) {
            [doc.fontInfos setValue:fontInfo forKey:fontKey];
        }
    }
}

- (NSString*)fontTagToFontKey:(NSString*)tag {
    return [self.fontKeysDict objectForKey:tag];
}

#pragma Debug
- (void)logPageContent {
    printData(pageContent);
    
    printf("\n==Resource==\n");
    printData([resources rawContent]);
    printf("\n============\n");
}

- (int)pageNumber {
    return (int)([doc.pages indexOfObject:self] + 1);
}
@end
