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
#import "GFont.h"
#import "GGlyph.h"
#import "GWord.h"
#import "GLine.h"
#import "GTextBlock.h"
#import "GMisc.h"

@implementation GDocument

- (IBAction)saveDocumentAs:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    NSArray *types = @[@"pdf"];
    [panel setAllowedFileTypes:types];
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            NSString *path = [[panel URL] path];
            [self saveAs:path];
            return ;
         }
    }];
}

- (void)saveAs:(NSString*)path {
    GPage *firstPage = [pages firstObject];
    [firstPage incrementalUpdate];
    [[parser stream] writeToFile:path atomically:YES];
}

- (void)awakeFromNib {
    // Resize window
    NSLog(@"View: %@", NSStringFromRect(self.bounds));
    NSRect rect = [[self window] frame];
    rect.size = NSMakeSize(1200, 1024);
    [[self window] setFrame: rect display: YES];
    
    rect = [self.enclosingScrollView.contentView frame]; // keep view width, and fix the right white margin
    rect.size.height += 150;
    [self setFrameSize:rect.size];
    
    [self scrollToTop];
    
    NSLog(@"View after resizing: %@", NSStringFromRect(self.bounds));
    
    // User space to device space scaling
    [self scaleUnitSquareToSize:NSMakeSize(kScaleFactor, kScaleFactor)];
    
    GParser *p = [GParser parser];
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *path = [mainBundle pathForResource:@"PEP_Incremental" ofType:@"pdf"];
    NSMutableData *d = [NSMutableData dataWithContentsOfFile:path];
    [p setStream:d];
       
    GStreamObject *stream = [p getObjectByRef:@"29-0"];
    NSData *decodedFontData = [stream getDecodedStreamContent];
    
    CGDataProviderRef cgdata = CGDataProviderCreateWithCFData((CFDataRef)decodedFontData);
    CGFontRef font = CGFontCreateWithDataProvider(cgdata);
    NSFont *f = (NSFont*)CFBridgingRelease(CTFontCreateWithGraphicsFont(font, 144, nil, nil));
    
    // Test tables
    printTableTagsForCGFont(font);
    
    // change font size
    // f = [NSFont fontWithDescriptor:[f fontDescriptor] size:144];
    
    s = [[NSMutableAttributedString alloc] initWithString:@"PEPB"];
    [s addAttribute:NSFontAttributeName value:f range:NSMakeRange(0, 4)];
    [s addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, 4)];
    
    CFRelease(font);
    CFRelease(cgdata);
    
    // Inits
    mode = kNoneMode;
    _addedRefkeys = [NSMutableArray array];
    
    // Test parsePages
    [self parsePages];
    
    // parse Content of first page
    [[pages firstObject] parsePageContent];
    
    // Make all mouse events work
    [self updateTrackingAreas];
}

- (void)updateTrackingAreas {
    if(trackingArea != nil) {
        [self removeTrackingArea:trackingArea];
    }
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingMouseMoved | NSTrackingInVisibleRect);
    trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:opts
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:trackingArea];
    [self.window invalidateCursorRectsForView:self];
}

- (void)parsePages {
    parser = [GParser parser];
    NSBundle *mainBundle = [NSBundle mainBundle];
    // TODO: Use test_xref.pdf by default without ability to custom file, will
    // do it later
    //file = [mainBundle pathForResource:@"test_xref" ofType:@"pdf"];
    file = [mainBundle pathForResource:@"Super Mario World" ofType:@"pdf"];
    NSMutableData *d = [NSMutableData dataWithContentsOfFile:file];
    [parser setStream:d];
    
    // Get trailer
    GDictionaryObject *trailer = [parser getTrailer];
    
    // Get Root ref
    GRefObject *root = [[trailer value] objectForKey:@"Root"];
    // Get catalog dictionary object
    NSLog(@"Root ref: %@", [root getRefString]);
    GDictionaryObject *catalogObject = [parser getObjectByRef:[root getRefString]];
    GRefObject *pagesRef = [[catalogObject value] objectForKey:@"Pages"];
    // Get pages dictionary object
    GDictionaryObject *pagesObject = [parser getObjectByRef:[pagesRef getRefString]];
    GArrayObject *kids = [[pagesObject value] objectForKey:@"Kids"];
    
    // Get GPage array
    pages = [NSMutableArray array];
    NSArray *array = [kids value];
    NSUInteger i;
    for (i = 0; i < [array count]; i++) {
        GRefObject *ref = (GRefObject*)[array objectAtIndex:i];
        GDictionaryObject *pageDict = [parser getObjectByRef:[ref getRefString]];
        GPage *page = [GPage create];
        [page setPageDictionary:pageDict];
        [page setParser:parser];
        [page setDocument:self];
        [pages addObject:page];
        [page setLastStreamOffset:(unsigned int)[[[parser lexer] stream] length]];
    }
    NSLog(@"[GDocument parsePages] pages: %ld", [pages count]);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSColor *bgColor = [NSColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];
    [bgColor set];
    NSRectFill([self bounds]);
    
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    GPage *page = [pages firstObject];
    [page render:context];
}

// GDocument's view coordinate origin is at bottom-left which is not flipped.
// For easy pages layout which would use flipped rect (origin at top-left),
// and we can convert the rect from flipped to no flipped.
- (NSRect)rectFromFlipped:(NSRect)r {
    NSRect bounds = [self bounds];
    float height = bounds.size.height;
    NSPoint newOrigin = NSMakePoint(r.origin.x, height - r.origin.y);
    NSRect ret = NSMakeRect(newOrigin.x, newOrigin.y - r.size.height, r.size.width , r.size.height);
    return ret;
}

- (void)scrollToTop {
    NSPoint pt = NSMakePoint(0.0, [[self.enclosingScrollView documentView]
                                      bounds].size.height);
    [self.enclosingScrollView.documentView scrollPoint:pt];
}

- (void)mouseMoved:(NSEvent *)event {
     GPage *p = [pages firstObject];
     [p mouseMoved:event];
}

- (void)mouseDown:(NSEvent *)event {
    GPage *p = [pages firstObject];
   
    [p mouseDown:event];
    /*NSUInteger i;
    NSMutableArray *glyphs = [[p textParser] glyphs];
    printf("%d glyphs in text parser", (int)[glyphs count]);
    for (i = 0; i < [glyphs count]; i++) {
        GGlyph *g = [glyphs objectAtIndex:i];
        printf("%s", [[g content] UTF8String]);
    }
    printf("\n");
    
    NSLog(@"List of text blocks");
    NSMutableArray *textBlocks = [[p textParser] makeTextBlocks];
    for (i = 0; i < [textBlocks count]; i++) {
        GTextBlock *tb = [textBlocks objectAtIndex:i];
        NSLog(@"*****");
        NSLog(@"%@", [tb textBlockStringWithLineFeed]);
    }
    NSLog(@"End list of text blocks");
    
    GTextBlock *lastTB = [textBlocks lastObject];
    NSArray *glyphsArray = [lastTB glyphs];
    for (i = 0; i < [glyphsArray count]; i++) {
        GGlyph *g = [glyphsArray objectAtIndex:i];
        NSLog(@"%@", [g content]);
    }
    
    NSRect f = [lastTB frame];
    NSPoint origin = f.origin;
    origin = translatePoint(origin, [p origin]);
    f.origin = origin;
    */
    //[p buildPageContent];
    //[self setNeedsDisplay:YES];
}

- (void)keyDown:(NSEvent *)event {
    GPage *p = [pages firstObject];
    [p keyDown:event];
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)setMode:(GDocumentMode)m {
    if (m != kTextEditMode) {
        _textEditor = nil;
    }
    mode = m;
    [self setNeedsDisplay:YES];
}

- (GDocumentMode)mode {
    return mode;
}

// Don't forget to add new ref to _addedRefkeys, so that we can get unique ref 
- (NSString*)generateNewRef {
    int objectNumber = 1;
    int generationNumber = 0;
    NSString *ref = [NSString stringWithFormat:@"%d-%d", objectNumber, generationNumber];
    while(![parser refObjectNotFound:ref] || [_addedRefkeys containsObject:ref]) {
        objectNumber += 1;
        ref = [NSString stringWithFormat:@"%d-%d", objectNumber, generationNumber];
    }
    [_addedRefkeys addObject:ref];
    return ref;
}
@end
