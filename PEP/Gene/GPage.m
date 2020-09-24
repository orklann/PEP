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

- (void)render:(CGContextRef)context {
    // Draw media box (a.k.a page boundary)
    NSRect pageRect = [self calculatePageMediaBox];
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context, pageRect);
    
    textState = [GTextState create];
    
    GInterpreter *interpreter = [GInterpreter create];
    [interpreter setParser:parser];
    [interpreter setInput:pageContent];
    [interpreter eval:context];
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
    NSLog(@"%@", NSStringFromRect(mediaBoxRect));
    NSRect bounds = [doc bounds];
    CGFloat pageX = NSMidX(bounds) - (w / 2);
    CGFloat pageY = kPageMargin;
    CGFloat pageWidth = w;
    CGFloat pageHeight = h;
    NSRect pageRectFlipped = NSMakeRect(pageX, pageY, pageWidth, pageHeight);
    NSRect pageRect = [doc rectFromFlipped:pageRectFlipped];
    return pageRect;
}
@end
