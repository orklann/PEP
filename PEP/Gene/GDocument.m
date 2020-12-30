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

- (NSMutableArray*)pages {
    return pages;
}

- (void)saveAs:(NSString*)path {
    GPage *firstPage = [pages firstObject];
    [firstPage incrementalUpdate];
    [[parser stream] writeToFile:path atomically:YES];
}

-(void)drawBorder {
    NSRect frameRect = [self bounds];
    NSBezierPath *textViewSurround = [NSBezierPath bezierPathWithRoundedRect:frameRect xRadius:0 yRadius:0];
    [textViewSurround setLineWidth:2];
    [[NSColor blackColor] set];
    [textViewSurround stroke];
}

- (void)awakeFromNib {
    self.forceDrawAllPage = YES;
    
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
    
    [self calculateAllPagesYOffset];
    
    
    [self resizeToFitAllPages];
    
    // Argly hack to initaily scroll to top, because it's bugy to scroll to top after setFrame;
    [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:NO block:^(NSTimer *timer) {
        [self scrollToTop];
    
        // Initially update visible pages
        //self.forceDrawAllPage = YES;
        [self updateVisiblePage];
        //[self setNeedsDisplay:YES];
    
        //self.forceDrawAllPage = NO;
    }];
    
    // parse Content of all pagea
    [self parsePagesContent];
    
    // Make all mouse events work
    [self updateTrackingAreas];
    
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

- (void)parsePages {
    parser = [GParser parser];
    NSBundle *mainBundle = [NSBundle mainBundle];
    // TODO: Use test_xref.pdf by default without ability to custom file, will
    // do it later
    //file = [mainBundle pathForResource:@"test_xref" ofType:@"pdf"];
    file = [mainBundle pathForResource:@"Sample_001" ofType:@"pdf"];
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
    NSLog(@"drawRect:");
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    
    if (self.forceDrawAllPage) {
        NSLog(@"Draw all page");
        [super drawRect:dirtyRect];
        NSColor *bgColor = [NSColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];
        [bgColor set];
        NSRectFill([self bounds]);
        
        for (GPage *page in pages) {
            [page render:context];
        }
        return ;
    }
    
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
            [page render:context];
            if (!renderedVisiblePage) {
                renderedVisiblePage = YES;
            }
        } else {
            if (renderedVisiblePage) {
                break;
            }
            NSLog(@"not render page: %d", (int)[pages indexOfObject:page]);
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
    self.forceDrawAllPage = NO;
    for (GPage *page in pages) {
        [page mouseMoved:event];
    }
}

- (void)mouseDown:(NSEvent *)event {
    self.forceDrawAllPage = NO;
    for (GPage *page in pages) {
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
    [self updateVisiblePage];
    [self setNeedsDisplayInRect:[self visibleRect]];
}
@end
