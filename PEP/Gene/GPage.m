//
//  GPage.m
//  PEP
//
//  Created by Aaron Elkins on 9/17/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GPage.h"
#import "GDecoders.h"
#import "GMisc.h"
#import "GInterpreter.h"
#import "GDocument.h"
#import "GFont.h"
#import "GTextParser.h"
#import "GWord.h"
#import "GLine.h"
#import "GTextBlock.h"
#import "GGlyph.h"

@implementation GPage

+ (id)create {
    GPage *p = [[GPage alloc] init];
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
    pageContent = [contentStream getDecodedStreamContent];
    
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
    [interpreter eval:context];
    
    
    if (textEditor != nil) {
        [textEditor draw:context];
    }
}

// Calculate media box for PDF page in user space coordinate
// Return rect with origin in bottom left
- (NSRect)calculatePageMediaBox {
    GArrayObject *mediaBox = [[pageDictionary value] objectForKey:@"MediaBox"];
    GNumberObject *xObj = [[mediaBox value] objectAtIndex:0];
    GNumberObject *yObj = [[mediaBox value] objectAtIndex:1];
    GNumberObject *widthObj = [[mediaBox value] objectAtIndex:2];
    GNumberObject *heightObj = [[mediaBox value] objectAtIndex:3];
    CGFloat x = [xObj getRealValue];
    CGFloat y = [yObj getRealValue];
    CGFloat w = [widthObj getRealValue];
    CGFloat h = [heightObj getRealValue];
    NSRect mediaBoxRect = NSMakeRect(x, y, w, h);
    NSLog(@"Page media box: %@", NSStringFromRect(mediaBoxRect));
    NSRect bounds = [doc bounds];
    CGFloat pageX = NSMidX(bounds) - (w / 2);
    CGFloat pageY = kPageMargin;
    CGFloat pageWidth = w;
    CGFloat pageHeight = h;
    NSRect pageRectFlipped = NSMakeRect(pageX, pageY, pageWidth, pageHeight);
    NSRect pageRect = [doc rectFromFlipped:pageRectFlipped];
    NSLog(@"page rect: %@", NSStringFromRect(pageRect));
    return pageRect;
}

- (GFont*)getFontByName:(NSString*)name {
    GFont *f = [GFont fontWithName:name page:self];
    return f;
}

- (NSFont*)getCurrentFont {
    GFont *font = [self getFontByName:[[self textState] fontName]];
    return [font getNSFontBySize:[[self textState] fontSize]];
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
    pageContent = [ret dataUsingEncoding:NSASCIIStringEncoding];
    NSLog(@"New Page Content");
    printData(pageContent);
    NSLog(@"END New Page Content");
}

- (void)redraw {
    [[self doc] setNeedsDisplay:YES];
}
@end
