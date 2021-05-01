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
#import "GBinaryData.h"
#import "GMisc.h"
#import "AppDelegate.h"

// TODO: TEST, REMOVE BELOW
#import "GColorSpace.h"

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

- (NSMutableArray*)pages {
    return pages;
}

- (void)saveAs:(NSString*)path {
    [self incrementalUpdate];
    [[parser stream] writeToFile:path atomically:YES];
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
    NSLog(@"GDocument: Debug incremental update");
    for (GPage *page in pages) {
        [page incrementalUpdate];
        page.dirty = NO;
    }
    
    NSMutableData *stream = [parser stream];
    // remove last added content from stream
    //[stream setLength:self.lastStreamOffset];
    
    int prevStartXRef = [parser getStartXRef];
    GDictionaryObject *trailerDict = [parser getTrailer];

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
    [parser updateXRefDictionary];
}

-(void)drawBorder {
    NSRect frameRect = [self bounds];
    NSBezierPath *textViewSurround = [NSBezierPath bezierPathWithRoundedRect:frameRect xRadius:0 yRadius:0];
    [textViewSurround setLineWidth:2];
    [[NSColor blackColor] set];
    [textViewSurround stroke];
}

- (void)awakeFromNib {
    self.dataToUpdate = [NSMutableArray array];

    NSLog(@"View: %@", NSStringFromRect(self.bounds));
    
    // User space to device space scaling
    [self scaleUnitSquareToSize:NSMakeSize(kScaleFactor, kScaleFactor)];
    
    // Setup notification for NSScrollViewDidEndLiveScrollNotification
    [[NSNotificationCenter  defaultCenter] addObserver:self selector:@selector(scrollViewDidEndLiveScroll:)
                                                  name:NSScrollViewDidEndLiveScrollNotification
                                                object:self.enclosingScrollView];
    
    // Setup notification for NSScrollViewDidLiveScrollNotification
    [[NSNotificationCenter  defaultCenter] addObserver:self selector:@selector(scrollViewDidLiveScroll:)
                                                  name:NSScrollViewDidLiveScrollNotification
                                                object:self.enclosingScrollView];

    // Inits
    mode = kNoneMode;
    _addedRefkeys = [NSMutableArray array];
    
    // Test parsePages
    [self parsePages];
    
    [self calculateAllPagesYOffset];
    
    
    [self resizeToFitAllPages];
    
    // parse Content of all pagea
    [self parsePagesContent];
    
    // Build cached fonts for all pages
    [self buildCachedFonts];
    
    // Build font encodings for all page
    [self buildFontEncodings];
    
    // Build font infos for all pages
    [self buildFontInfos];
    
    // Argly hack to initaily scroll to top, because it's bugy to scroll to top after setFrame;
    [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:NO block:^(NSTimer *timer) {
        [self scrollToTop];
    
        // Initially update visible pages
        [self updateVisiblePage];
        
        // Prewarm nearby pages around visible pages
        [self prewarmRenderNearbyPages];
        
        [self setNeedsDisplayInRect:[self visibleRect]];
    }];
    
    // Make all mouse events work
    [self updateTrackingAreas];
    
    // NOTE: Integration Test for GSepartionColorSpace with PDF: coders-at-work.pdf
    // [self testGSeparationColorSpace];
}

- (void)resizeToFitAllPages {
    CGFloat height = kPageMargin;
    for (GPage *page in pages) {
        NSRect pageRect = [page calculatePageMediaBox];
        height += pageRect.size.height;
        height += kPageMargin;
    }
    NSRect docRect = [[self.window contentView] frame];
    docRect.size.height = height * kScaleFactor;
    NSScroller *verticalScroller = [self.enclosingScrollView verticalScroller];
    NSRect scrollerRect = [verticalScroller bounds];
    CGFloat scrollerWidth = scrollerRect.size.width;
    docRect.size.width -= scrollerWidth;
    docRect.origin = NSZeroPoint;
    [self setFrame:docRect];
}

- (void)calculateAllPagesYOffset {
    CGFloat yOffset = 0.0;
    for (GPage *page in pages) {
        [page setPageYOffsetInDoc:yOffset];
        NSRect rect = [page calculatePageMediaBox];
        CGFloat height = rect.size.height;
        yOffset += height;
        yOffset += kPageMargin;
    }
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

- (void)parsePagesContent {
    for (GPage *page in pages) {
        [page parsePageContent];
    }
}

- (void)parsePagesByRef:(GRefObject*)refObject {
    GDictionaryObject *object = [parser getObjectByRef:[refObject getRefString]];
    GNameObject *type = [[object value] objectForKey:@"Type"];
    
    // It's pages dictionary object with /Type /Pages
    if ([[type value] isEqualToString:@"Pages"]) {
        GArrayObject *kids = [[object value] objectForKey:@"Kids"];
        NSArray *array = [kids value];
        NSUInteger i;
        for (i = 0; i < [array count]; i++) {
            GRefObject *ref = (GRefObject*)[array objectAtIndex:i];
            [self parsePagesByRef:ref];
        }
    } else if ([[type value] isEqualToString:@"Page"]){ // It's page dictionary object with /Type /Page
        GPage *page = [GPage create];
        [page setPageDictionary:object];
        [page setParser:parser];
        [page setDocument:self];
        [page setPageRef:refObject];
        [pages addObject:page];
        [page setLastStreamOffset:(unsigned int)[[[parser lexer] stream] length]];
    }
}

- (void)parsePages {
    pages = [NSMutableArray array];
    
    parser = [GParser parser];
    //NSBundle *mainBundle = [NSBundle mainBundle];
    // TODO: Use test_xref.pdf by default without ability to custom file, will
    // do it later
    //file = [mainBundle pathForResource:@"test_xref" ofType:@"pdf"];
    //file = [mainBundle pathForResource:@"Sample_001" ofType:@"pdf"];
    //file = @"/Users/aaron/Downloads/Jazz_Theory_Explained.pdf";
    NSMutableData *d = [NSMutableData dataWithContentsOfFile:self.file];
    [parser setStream:d];
    
    [parser updateXRefDictionary];
    
    // Get trailer
    GDictionaryObject *trailer = [parser getTrailer];
    
    // Get Root ref
    GRefObject *root = [[trailer value] objectForKey:@"Root"];
    // Get catalog dictionary object
    NSLog(@"Root ref: %@", [root getRefString]);
    GDictionaryObject *catalogObject = [parser getObjectByRef:[root getRefString]];
    GRefObject *pagesRef = [[catalogObject value] objectForKey:@"Pages"];
    [self parsePagesByRef:pagesRef];
    
    NSLog(@"[GDocument parsePages] pages: %ld", [pages count]);
}

- (void)drawRect:(NSRect)dirtyRect {
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    
    // Test: draw GDocument border with 2pt black color
    //[self drawBorder];
    
    BOOL renderedVisiblePage = NO;
    NSLog(@"=====Visible Pages=====");
    for (GPage *page in visiblePages) {
        NSLog(@"page %d", (int)[pages indexOfObject:page]);
    }
    
    for (GPage *page in pages) {
        if ([visiblePages containsObject:page]) {
            NSLog(@"render page: %d", (int)[pages indexOfObject:page]);
            // TODO: Remove this line, it's here just for testing graphic operators
            [page setNeedUpdate:YES];
            
            [page render:context];
            if (!renderedVisiblePage) {
                renderedVisiblePage = YES;
            }
        } else {
            if (renderedVisiblePage) {
                break;
            }
            [page translateToPageOrigin:context];
        }
    }
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
    for (GPage *page in visiblePages) {
        NSPoint location = [event locationInWindow];
        NSPoint point = [self convertPoint:location fromView:nil];
        if (NSPointInRect(point, [page calculatePageMediaBox])) {
            [page mouseMoved:event];
            break;
        }
    }
}

- (void)mouseDown:(NSEvent *)event {
    for (GPage *page in visiblePages) {
        [page mouseDown:event];
    }
}

- (void)keyDown:(NSEvent *)event {
    if ([self textEditor]) {
        [[self textEditor] keyDown:event];
    }
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)setMode:(GDocumentMode)m {
    if (m != kTextEditMode) {
        _textEditor = nil;
    }
    mode = m;
    [self setNeedsDisplayInRect:[self visibleRect]];
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

- (void)updateVisiblePage {
    visiblePages = [NSMutableArray array];
    NSRect visibleRect = [self visibleRect];
    BOOL foundPage = NO;
    for (GPage *page in pages) {
        NSRect pageRect = [page calculatePageMediaBox];
        if (NSIntersectsRect(pageRect, visibleRect)) {
            [visiblePages addObject:page];
            if (!foundPage) foundPage = YES;
        } else {
            if (foundPage) {
                break;
            }
        }
    }
}

- (void)scrollViewDidEndLiveScroll:(NSNotification *)notification {
    [self updateVisiblePage];
    [self setNeedsDisplayInRect:[self visibleRect]];
}

- (void)scrollViewDidLiveScroll:(NSNotification *)notification {
    NSArray *oldVisiblePages = [NSArray arrayWithArray:visiblePages];
    [self updateVisiblePage];
    
    // Only redraw while visible pages are changed
    if (![visiblePages isEqualToArray:oldVisiblePages]) {
        NSRect rect = NSZeroRect;
        for (GPage *p in visiblePages) {
            NSRect pageRect = [p calculatePageMediaBox];
            pageRect.size.width = [self bounds].size.width;
            pageRect.origin.x = 0;
            rect = NSUnionRect(rect, pageRect);
        }
        self.preparedContentRect = rect;
        [self setNeedsDisplayInRect:rect];
    } else {
        [self prewarmRenderNearbyPages];
    }
}

- (void)buildFontEncodings {
    self.fontEncodings = [NSMutableDictionary dictionary];
    for (GPage *page in pages) {
        [page buildFontEncodings];
    }
}

- (void)buildFontInfos {
    self.fontInfos = [NSMutableDictionary dictionary];
    for (GPage *page in pages) {
        [page buildFontInfos];
    }
}

- (void)buildCachedFonts {
    self.cachedFonts = [NSMutableDictionary dictionary];
    for (GPage *page in pages) {
        [page buildCachedFonts];
    }
}

#pragma Debug
- (void)logPageContent:(int)pageNumber {
    if (pageNumber >= 1 && pageNumber <= [pages count]) {
        GPage *page = [pages objectAtIndex:pageNumber-1];
        [page logPageContent];
    }
}

// This make sure NSView also draw the overdraw region, so that visible pages are fully drawn,
// not only the visible rect
- (void)prepareContentInRect:(NSRect)rect {
    [super prepareContentInRect:self.preparedContentRect];
}

- (void)prewarmRenderNearbyPages {
    GPage *firstPage = [visiblePages firstObject];
    GPage *lastPage = [visiblePages lastObject];
    int firstIndex = (int)[pages indexOfObject:firstPage];
    int lastIndex = (int)[pages indexOfObject:lastPage];
    int index;
    
    index = firstIndex - 2;
    if (index >= 0) {
        GPage *page = [pages objectAtIndex:index];
        [page performSelectorInBackground:@selector(prewarmRender) withObject:nil];
    }
    
    index = firstIndex - 1;
    if (index >= 0) {
        GPage *page = [pages objectAtIndex:index];
        [page performSelectorInBackground:@selector(prewarmRender) withObject:nil];
    }
    
    index = lastIndex + 2;
    if (index <= [pages count] - 1) {
        GPage *page = [pages objectAtIndex:index];
        [page performSelectorInBackground:@selector(prewarmRender) withObject:nil];
    }
    
    index = lastIndex + 1;
    if (index <= [pages count] - 1) {
        GPage *page = [pages objectAtIndex:index];
        [page performSelectorInBackground:@selector(prewarmRender) withObject:nil];
    }
}

#pragma Integration Testing
- (void)testGSeparationColorSpace {
    GPage *firstPage = [pages firstObject];
    GColorSpace *cs = [GColorSpace colorSpaceWithName:@"Cs8" page:firstPage];
    
    // Construct GCommandObject to pass to mapColor:
    NSString *s = @"0 cs";
    GParser *p2 = [GParser parser];
    [p2 setStream:[s dataUsingEncoding:NSASCIIStringEncoding]];
    [p2 parse];
    NSArray *result = [p2 objects];
    GNumberObject *n = [result firstObject];
    GCommandObject *cmd = [result lastObject];
    
    NSArray *args = [NSArray arrayWithObjects:n, nil];
    [cmd setArgs:args];
    
    // Map color by using alternate color space
    NSColor *color = [cs mapColor:cmd];
    
    // Test: It should output `1 1 1 1`
    NSLog(@"TEST: mapped color: %@", color);
    NSColor *c1 = [NSColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    if (CGColorEqualToColor([c1 CGColor], [color CGColor])){
        NSLog(@"TEST: testGSeparationColorSpace pass");
    } else {
        NSLog(@"TEST: testGSeparationColorSpace failed");
    }
}
@end
