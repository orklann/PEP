//
//  GDocument.m
//  PEP
//
//  Created by Aaron Elkins on 9/9/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GDocument.h"
#import "GParser.h"
#import "GDecoders.h"

@implementation GDocument
- (void)awakeFromNib {
    GParser *p = [GParser parser];
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *path = [mainBundle pathForResource:@"test_xref" ofType:@"pdf"];
    NSData *d = [NSData dataWithContentsOfFile:path];
    [p setStream:d];
       
    GIndirectObject *contentIndirect = [p getObjectByRef:@"19-0"];
    GStreamObject *stream = [contentIndirect object];
    NSData *fontData = [stream streamContent];
    NSData *decodedFontData = decodeFlate(fontData);
    
    CGDataProviderRef cgdata = CGDataProviderCreateWithCFData((CFDataRef)decodedFontData);
    CGFontRef font = CGFontCreateWithDataProvider(cgdata);
    NSFont *f = (NSFont*)CFBridgingRelease(CTFontCreateWithGraphicsFont(font, 144, nil, nil));
    
    // change font size
    // f = [NSFont fontWithDescriptor:[f fontDescriptor] size:144];
    
    s = [[NSMutableAttributedString alloc] initWithString:@"PEPB"];
    [s addAttribute:NSFontAttributeName value:f range:NSMakeRange(0, 4)];
    [s addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, 4)];
    
    CFRelease(font);
    CFRelease(cgdata);
    
    // Test parsePages
    [self parsePages];
}

- (void)parsePages {
    parser = [GParser parser];
    NSBundle *mainBundle = [NSBundle mainBundle];
    // TODO: Use test_xref.pdf by default without ability to custom file, will
    // do it later
    file = [mainBundle pathForResource:@"test_xref" ofType:@"pdf"];
    NSData *d = [NSData dataWithContentsOfFile:file];
    [parser setStream:d];
    
    // Get trailer
    GDictionaryObject *trailer = [parser getTrailer];
    
    // Get Root ref
    GRefObject *root = [[trailer value] objectForKey:@"Root"];
    NSString *catalogRef = [NSString stringWithFormat:@"%d-%d",
                            [root objectNumber], [root generationNumber]];
    GIndirectObject *catalogIndirect = [parser getObjectByRef:catalogRef];
    // Get catalog dictionary object
    GDictionaryObject *catalogObject = [catalogIndirect object];
    GRefObject *pagesRef = [[catalogObject value] objectForKey:@"Pages"];
    GIndirectObject *pagesIndirect = [parser getObjectByRef:
                                    [NSString stringWithFormat:@"%d-%d",
                                    [pagesRef objectNumber], [pagesRef generationNumber]]];
    // Get pages dictionary object
    GDictionaryObject *pagesObject = [pagesIndirect object];
    GArrayObject *kids = [[pagesObject value] objectForKey:@"Kids"];
    
    // Get GPage array
    pages = [NSMutableArray array];
    NSArray *array = [kids value];
    NSUInteger i;
    for (i = 0; i < [array count]; i++) {
        GRefObject *ref = (GRefObject*)[array objectAtIndex:i];
        NSString *refString = [NSString stringWithFormat:@"%d-%d",
                               [ref objectNumber], [ref generationNumber]];
        GIndirectObject *indirect = [parser getObjectByRef:refString];
        GDictionaryObject *pageDict = [indirect object];
        GPage *page = [GPage create];
        [page setPageDictionary:pageDict];
        [page setParser:parser];
        [pages addObject:page];
    }
    NSLog(@"[GDocument parsePages] pages: %ld", [pages count]);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [[NSColor whiteColor] set];
    NSRectFill([self bounds]);
    
    [s drawAtPoint:NSMakePoint(0, 0)];
    NSLog(@"drawRect called.");
    // Drawing code here.
}

- (BOOL)isFlipped {
    return YES;
}
@end
