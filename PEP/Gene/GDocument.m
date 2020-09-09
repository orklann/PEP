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
       
    NSDictionary *xref = [p parseXRef];
    GXRefEntry *x = [xref objectForKey:@"19-0"];
    unsigned int offset = [x offset];
    [[p lexer] setPos:offset];
    GIndirectObject* contentIndirect = (GIndirectObject*)[p parseNextObject];
    GStreamObject *stream = [contentIndirect object];
    NSData *fontData = [stream streamContent];
    NSData *decodedFontData = decodeFlate(fontData);
    
    CGDataProviderRef cgdata = CGDataProviderCreateWithCFData((CFDataRef)decodedFontData);
    CGFontRef font = CGFontCreateWithDataProvider(cgdata);
    NSFont *f = (NSFont*)CFBridgingRelease(CTFontCreateWithGraphicsFont(font, 46, nil, nil));
    
    // change font size
    f = [NSFont fontWithDescriptor:[f fontDescriptor] size:144];
    
    s = [[NSMutableAttributedString alloc] initWithString:@"PEPB"];
    [s addAttribute:NSFontAttributeName value:f range:NSMakeRange(0, 4)];
    [s addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, 4)];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [[NSColor whiteColor] set];
    NSRectFill([self bounds]);
    
    [s drawAtPoint:NSMakePoint(0, 0)];
    NSLog(@"drawRect called.");
    // Drawing code here.
}

@end
