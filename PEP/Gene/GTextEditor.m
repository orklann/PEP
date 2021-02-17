//
//  GTextEditor.m
//  PEP
//
//  Created by Aaron Elkins on 10/14/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GTextEditor.h"
#import "GPage.h"
#import "GTextBlock.h"
#import "GGlyph.h"
#import "GWord.h"
#import "GLine.h"
#import "GFont.h"
#import "GDocument.h"
#import "GMisc.h"
#import "GConstants.h"
#import "GBinaryData.h"
#import "GTextParser.h"
#import "GWrappedLine.h"
#import "PEPWindow.h"
#import "PEPMisc.h"
#import "GInterpreter.h"
#import "GEncodings.h"

#define kLeftArrow 123
#define kRightArrow 124
#define kDownArrow 125
#define kUpArrow 126

@implementation GTextEditor
+ (id)textEditorWithPage:(GPage *)p textBlock:(GTextBlock *)tb {
    GTextEditor *editor = [[GTextEditor alloc] initWithPage:p textBlock:tb];
    return editor;
}

- (GTextEditor*)initWithPage:(GPage *)p textBlock:(GTextBlock*)tb {
    self = [super init];
    self.page = p;
    PEPWindow *window = (PEPWindow*)self.page.doc.window;
    [self setDelegate:[window sideView]];
    textBlock = tb;
    insertionPointIndex = 0;
    // Update font name, font size
    [self updateFontNameAndFontSize];
    self.drawInsertionPoint = YES;
    self.isEditing = NO;
    self.firstUsed = YES;
    self.commandsUpdated = NO;
    self.editingGlyphs = [NSMutableArray array];
    editorWidth = [textBlock frame].size.width;
    editorHeight = [textBlock frame].size.height;
    everWrapWord = NO;
    // Initialize ctm, textMatrix (First glyph)
    GGlyph *firstGlyph = [[textBlock glyphs] firstObject];
    ctm = [firstGlyph ctm];
    textMatrix = [firstGlyph textMatrix];
    
    // First time draw the text, we must ensure to save editing glyphs
    // Other time to save it is after editing text.
    // Call [self insertChar:font:] etc.
    [self saveEditingGlyphs];
    blinkTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (self.drawInsertionPoint) {
            self.drawInsertionPoint = NO;
        } else {
            self.drawInsertionPoint = YES;
        }
        [self redraw];
    }];
    
    // Notify delegate to udpate text state
    if ([_delegate respondsToSelector:@selector(textStateDidChange:)]) {
        [_delegate textStateDidChange:self];
    }
    return self;
}

- (void)addGlyphIndexToEditingGlyphs:(int)index {
    NSNumber *n = [NSNumber numberWithInt:index];
    [self.editingGlyphs addObject:n];
}

- (void)removeGlyphIndexInEdittingGlyphs:(int)index {
    for (NSNumber *n in self.editingGlyphs) {
        if ([n intValue] == index) {
            [self.editingGlyphs removeObject:n];
            return ;
        }
    }
}

- (void)saveEditingGlyphs {
    self.editingGlyphs = [NSMutableArray array];
    NSArray *localGlyphs = [textBlock glyphs];
    /* Original glyphs in page */
    NSArray *pageGlyphs = [[self.page textParser] glyphs];
    for (GGlyph *g in localGlyphs) {
        int index = (int)[pageGlyphs indexOfObject:g];
        [self addGlyphIndexToEditingGlyphs:index];
    }
}

- (void)restoreEditingGlyphsToGlyphs {
    glyphs = [NSMutableArray array];
    /* Original glyphs in page */
    NSArray *pageGlyphs = [[self.page textParser] glyphs];
    for (NSNumber *n in self.editingGlyphs) {
        int index = [n intValue];
        GGlyph *g = [pageGlyphs objectAtIndex:index];
        [glyphs addObject:g];
    }
}

- (GTextBlock*)getTextBlock {
    if (self.firstUsed) {
        self.firstUsed = NO;
        return textBlock;
    } else {
        // By this, we get glyphs read for GTextParser to get the text block
        [self restoreEditingGlyphsToGlyphs];
        GTextParser *textParser = [GTextParser create];
        [textParser setGlyphs:glyphs];
        GTextBlock *tb = [textParser mergeLinesToTextblock];
        return tb;
    }
}

- (GTextBlock*)getTextBlockByCachedGlyphs {
    GTextParser *textParser = [GTextParser create];
    [textParser setGlyphs:cachedGlyphs];
    GTextBlock *tb = [textParser mergeLinesToTextblock];
    return tb;
}

- (void)redraw {
    if (self.isEditing) return ;
    GDocument *doc = (GDocument*)[(GPage*)self.page doc];
    [doc setNeedsDisplayInRect:[doc visibleRect]];
}

- (void)drawInsertionPoint:(CGContextRef)context {
    NSRect rect = [self getInsertionPoint];
    
    // Check if context's origin is in (0, 0), need to
    // add page's origin (x, y) to get in view coordinage
    CGAffineTransform ctm = CGContextGetCTM(context);
    if (ctm.tx == 0.0 && ctm.ty == 0.0) {
        rect = [self.page rectFromPageToView:rect];
    }
    
    NSPoint start = NSMakePoint(NSMinX(rect), NSMinY(rect));
    NSPoint end = NSMakePoint(NSMinX(rect), NSMaxY(rect));
    CGContextSetRGBStrokeColor(context, 0.22, 0.66, 0.99, 1.0);
    CGContextSetLineWidth(context, 1.0 / (kScaleFactor));
    CGContextMoveToPoint(context, (int)(start.x) + 0.5, (int)(start.y) - 0.5);
    CGContextAddLineToPoint(context, (int)(end.x) + 0.5, (int)(end.y) - 0.5);
    CGContextStrokePath(context);
}

- (void)draw:(CGContextRef)context {
    textBlock = [self getTextBlock];
    
    // Draw text editor border with 1 pixel width;
    NSRect frame = [self enlargedFrame];
    
    // Check if context's origin is in (0, 0), need to
    // add page's origin (x, y) to get in view coordinage
    CGAffineTransform ctm = CGContextGetCTM(context);
    if (ctm.tx == 0.0 && ctm.ty == 0.0) {
        frame = [self.page rectFromPageToView:frame];
    }
    
    frame = NSInsetRect(frame, 0.5, 0.5);
    // Dash pattern: pattern 6 times “solid”, 3 times “empty”
    CGFloat dash[2] = {6, 3};
    CGContextSetLineDash(context, 0, dash, 2);
    CGContextSetLineWidth(context, 1.5 / (kScaleFactor));
    CGContextSetRGBStrokeColor(context, 0.22, 0.66, 0.99, 1.0);
    CGContextStrokeRect(context, frame);
    
    // Back to normal dash pattern
    CGFloat normal[1] = {1};
    CGContextSetLineDash(context, 0, normal, 0);
    
    if (self.drawInsertionPoint) {
        [self drawInsertionPoint:context];
    }
}

- (NSRect)frame {
    if (textBlock == nil) {
        NSRect frame = firstGlyphFrame;
        frame.size.width = editorWidth;
        frame.size.height = editorHeight;
        return frame;
    }
    
    NSArray *glyphs = [textBlock glyphs];
    
    // Update firstGlyphFrame daynamically
    if ([glyphs count] >= 1) { // if we have at least one glyph
        GGlyph *firstGlyph = [glyphs firstObject];
        firstGlyphFrame = [firstGlyph frame];
    }
    NSRect frame =  [textBlock frame];
    frame.size.width = editorWidth;
    frame.size.height = editorHeight;
    return frame;
}

- (CGFloat)getEditorWidth {
    // 5 points margin on both sides
    // NOTE: Remove 5 points margin on both side, so that prevent wordwrapping change
    //       text layout while entering new text (For example: Super Mario World.pdf)
    //
    return editorWidth;// + (5 * 2);
}

- (NSRect)enlargedFrame {
    NSRect rect = [textBlock frame];
    rect.size.width = editorWidth;
    return NSInsetRect(rect, -3, -3);
}

- (NSRect)getInsertionPoint {
    NSRect ret;
    if (textBlock == nil) {
        NSRect rect = firstGlyphFrame;
        CGFloat minX = NSMinX(rect);
        CGFloat minY = NSMinY(rect);
        CGFloat height = NSHeight(rect);
        ret = NSMakeRect(minX, minY, 1, height);
        return ret;
    }
    
    NSArray *glyphs = [textBlock glyphs];
    if (insertionPointIndex <= [glyphs count] - 1) {
        GGlyph *g = [glyphs objectAtIndex:insertionPointIndex];
        NSRect rect = [g frame];
        CGFloat minX = NSMinX(rect);
        CGFloat minY = NSMinY(rect);
        CGFloat height = NSHeight(rect);
        ret = NSMakeRect(minX, minY, 1, height);
    } else {
        GGlyph *g = [glyphs lastObject];
        NSRect rect = [g frame];
        CGFloat maxX = NSMaxX(rect);
        CGFloat minY = NSMinY(rect);
        CGFloat height = NSHeight(rect);
        ret = NSMakeRect(maxX, minY, 1, height);
    }
    return ret;
}

- (void)keyDown:(NSEvent*)event {
    NSArray *glyphs = [textBlock glyphs];
    int keyCode = [event keyCode];
    if (keyCode == kLeftArrow) {
        if (insertionPointIndex - 1 >= 0) {
            insertionPointIndex--;
        }
        [self updateFontNameAndFontSize];
        if ([_delegate respondsToSelector:@selector(textStateDidChange:)]) {
            [_delegate textStateDidChange:self];
        }
    } else if (keyCode == kRightArrow) {
        if (insertionPointIndex + 1 <= [glyphs count]) {
            insertionPointIndex++;
        }
        [self updateFontNameAndFontSize];
        if ([_delegate respondsToSelector:@selector(textStateDidChange:)]) {
            [_delegate textStateDidChange:self];
        }
    } else if (keyCode == kUpArrow) {
        [self moveInsertionPointUp];
        [self updateFontNameAndFontSize];
        if ([_delegate respondsToSelector:@selector(textStateDidChange:)]) {
            [_delegate textStateDidChange:self];
        }
    } else if (keyCode == kDownArrow) {
        [self moveInsertionPointDown];
        [self updateFontNameAndFontSize];
        if ([_delegate respondsToSelector:@selector(textStateDidChange:)]) {
            [_delegate textStateDidChange:self];
        }
    } else {
        NSString *ch =[event characters];
        unichar key = [ch characterAtIndex:0];
        if (event.keyCode == 36) { // Enter key
            [self insertChar:@"\n"];
        } else if(key == NSDeleteCharacter) {
            [self deleteCharacter];
        } else {
            /*
             * Fixed: Tab character is reandered as a box while opened with other
             *        PDF reader.
             */
            if ([ch isEqualToString:@"\t"]) {
                ch = @" ";  // NOTE: ch is now a Tab character, not a space
            }
            [self insertChar:ch];
            [self updateFontNameAndFontSize];
        }
        self.page.dirty = YES;
    }
    [self redraw];
}

- (int)nearestGlyphInPosition:(NSPoint)p {
    int ret = -1;
    NSArray *glyphs = [textBlock glyphs];
    int i;
    for (i = 0; i < [glyphs count]; i++) {
        GGlyph *g = [glyphs objectAtIndex:i];
        NSRect frame = [g frame];
        frame = [self.page rectFromPageToView:frame];
        if (NSPointInRect(p, frame)) {
            ret = i;
            return ret;
        }
    }
    
    // Move insertion point to last glyph of line, if clicking at the end area
    // of that line
    for (i = 0; i < [[textBlock lines] count]; i++) {
        GLine *line = [[textBlock lines] objectAtIndex:i];
        NSRect lineFrame = [line frame];
        lineFrame = [self.page rectFromPageToView:lineFrame];
        CGFloat maxX = NSMaxX(lineFrame);
        CGFloat y = lineFrame.origin.y;
        NSRect blockFrame = [textBlock frame];
        NSSize blockSize = blockFrame.size;
        CGFloat width = blockSize.width - lineFrame.size.width;
        NSRect rect = NSMakeRect(maxX, y, width, lineFrame.size.height);
        
        if (NSPointInRect(p, rect)) {
            GGlyph *last = [[line glyphs] lastObject];
            if (last.indexOfBlock == [glyphs count] - 1) {
                ret = last.indexOfBlock;
            } else {
                ret = last.indexOfBlock - 1;
            }
        }
        
    }
    return ret;
}

- (void)mouseDown:(NSEvent*)event {
    NSPoint location = [event locationInWindow];
    NSPoint point = [self.page.doc convertPoint:location fromView:nil];
    int glyphIndex = [self nearestGlyphInPosition:point];
    if (glyphIndex != -1) { // Successfully checked glyph in point
        NSArray *glyphs = [textBlock glyphs];
        GGlyph *g = [glyphs objectAtIndex:glyphIndex];
        NSRect frame = [g frame];
        frame = [self.page rectFromPageToView:frame];
        CGFloat midX = NSMidX(frame);
        if (point.x <= midX) {
            insertionPointIndex = [g indexOfBlock];
        } else {
            insertionPointIndex = [g indexOfBlock] + 1;
        }
        if (insertionPointIndex > (int)[glyphs count]) {
            insertionPointIndex = (int)[glyphs count];
        }
        self.drawInsertionPoint = YES;
        [self redraw];
    }
    if ([_delegate respondsToSelector:@selector(textStateDidChange:)]) {
        [_delegate textStateDidChange:self];
    }
}

/**
 * Think through insertion point management carefully, it's just complex to take
 * edge cases into account.
 *
 *
 *
 *
 */

- (void)insertChar:(NSString *)ch font:(NSFont*)font fontTag:(NSString*)fontName{
    NSMutableArray *glyphs = [self.page.textParser glyphs];
    
    //
    // If no text in text editor, we insert based on the last deleted glyph
    //
    if (textBlock == nil) {
        CGAffineTransform ctm = lastDeletedGlyph.ctm;
        CGAffineTransform tm = lastDeletedGlyph.textMatrix;
        CGFloat fontSize = lastDeletedGlyph.fontSize;
        
        GGlyph *g = [GGlyph create];

        [g setContent:ch];
        [g setCtm:ctm];
        [g setTextMatrix:tm];
        [g setFontName:fontName];
        [g setFontSize:fontSize];
        [g setFont:font];
        [g setEncoding:MacExpertEncoding];
        CGGlyph cgGlyph = [self.page.interpreter getCGGlyphForGGlyph:g];
        [g setGlyph:cgGlyph];
        
        // Update width for new glyph
        [g updateGlyphWidth];
        [g updateGlyphFrame];
        [g updateGlyphFrameInGlyphSpace];
        
        [glyphs addObject:g]; // Add this new glyph at the end

        
        // Add the new glyph index to text editor's editing glyphs
        [self addGlyphIndexToEditingGlyphs:(int)[glyphs count] - 1];
        insertionPointIndex++;
        
        // Update cached glyphs for word wrap use
        [self updateCachedGlyphs:[textBlock glyphs] newGlyph:g];
        return ;
    }
    
    GGlyph *currentGlyph = [self getCurrentGlyph];
    GGlyph *prevGlyph = [self getPrevGlyph];
    
    CGAffineTransform ctm;
    CGAffineTransform tm;
    CGFloat fontSize;
    
    GGlyph *g = [GGlyph create];
    [g setContent:ch];
    
    if (currentGlyph && ![self isCurrentGlyphLastGlyph]) {
        ctm = currentGlyph.ctm;
        tm = currentGlyph.textMatrix;
        fontSize = currentGlyph.fontSize;
        
        // These three are needed for updating width below
        [g setTextMatrix:tm];
        [g setEncoding:currentGlyph.encoding];
        [g setFont:font];
        
        // Calculate deltaX
        [g updateGlyphWidth];
        CGFloat deltaX = g.width;
        
        [self moveGlyphsIncludeAfter:currentGlyph byDeltaX:deltaX];
    } else {
        // Current glyph is nil, means we are at the end of text block,
        // we use previous glyph info
        ctm = prevGlyph.ctm;
        tm = prevGlyph.textMatrix;
        fontSize = prevGlyph.fontSize;
        // Also new glyph ctm need to add previous glyph width
        tm.tx += prevGlyph.width;
        [g setEncoding:prevGlyph.encoding];
    }
    
    [g setCtm:ctm];
    [g setTextMatrix:tm];
    [g setFontName:fontName];
    [g setFontSize:fontSize];
    [g setFont:font];
    CGGlyph cgGlyph = [self.page.interpreter getCGGlyphForGGlyph:g];
    [g setGlyph:cgGlyph];
    
    // Update width for new glyph
    [g updateGlyphWidth];
    [g updateGlyphFrame];
    [g updateGlyphFrameInGlyphSpace];
    
    [glyphs addObject:g];

    // Add the new glyph index to text editor's editing glyphs
    [self addGlyphIndexToEditingGlyphs:(int)[glyphs count] - 1];
    insertionPointIndex++;
    
    // Update text block immediately to prevent only update text block while redrawing,
    // which will sometimes cause glyph index out of bounds for [GTextEditor getCurrentGlyph] etc
    textBlock = [self getTextBlock];
    
    // Update cached glyphs for word wrap use
    [self updateCachedGlyphs:[textBlock glyphs] newGlyph:g];
}

- (void)insertChar:(NSString *)ch {
    if (self.isEditing) return ;
    self.isEditing = YES;
    NSString *fontName = [self pdfFontName];
    NSString *newFontTag;
    CGFloat fontSize = [self fontSize];
    NSFont *font;
    PEPSideView *sideView = [self getSideView];
    NSString *selectedFont = [sideView getSelectedFontName];
    if ([selectedFont containsString:@"+"]) {
        GFont *gFont = [GFont fontWithName:fontName page:self.page];
        font = [gFont getNSFontBySize:fontSize];
    } else {
        if (![self isCurrentFontMatchesSelected]) {
            font = [NSFont fontWithName:selectedFont size:fontSize];
            newFontTag = [self.page generateNewPDFFontTag];
            fontName = newFontTag;
            [self setPdfFontName:fontName];
            [self.page addNewFont:font withPDFFontTag:fontName];
        } else {
            // NOTE: We still add new font if selected font is the same as origin font in PDF.
            // But we need to skip adding original font tag from "Font" array from page resource.
            // For this, see [GPage addNewAddedFontsForUpdating]
            font = [NSFont fontWithName:selectedFont size:fontSize];
            [self.page addNewFont:font withPDFFontTag:fontName];
        }
    }
    
    [self insertChar:ch font:font fontTag:fontName];
    // Do word wrap here, use cached glyphs 
    [self doWordWrap];
    [[self.page textParser] setCached:NO];
    self.isEditing = NO;
}

- (BOOL)isCurrentGlyphLastGlyph {
    int index = insertionPointIndex;
    if (index > [[textBlock glyphs] count] - 1){
        return YES;
    }
    return NO;
}

- (GGlyph*)getCurrentGlyph {
    GGlyph *currentGlyph;
    int index = insertionPointIndex;
    if (index >= 0 && index <= [[textBlock glyphs] count] - 1) {
        currentGlyph = [[textBlock glyphs] objectAtIndex:index];
        return currentGlyph;
    }
    
    if (index > [[textBlock glyphs] count] - 1) {
        currentGlyph = [[textBlock glyphs] objectAtIndex:index - 1];
        return currentGlyph;
    }
    return nil;
}

- (GGlyph*)getPrevGlyph {
    GGlyph *prevGlyph;
    int index = insertionPointIndex - 1;
    if (index >= 0 && index <= [[textBlock glyphs] count] - 1) {
        prevGlyph = [[textBlock glyphs] objectAtIndex:index];
        return prevGlyph;
    }
    
    if (index < 0) {
        prevGlyph = [[textBlock glyphs] objectAtIndex:0];
        return prevGlyph;
    }
    return nil;
}

- (void)deleteCharacter {
    if (self.isEditing) return ;
    self.isEditing = YES;
    [self deleteCharacterInInsertionPoint];
    // Do word wrap
    [self doWordWrap];
    [[self.page textParser] setCached:NO];
    self.isEditing = NO;
}

- (void)deleteCharacterInInsertionPoint {
    // No text in text editor
    if (textBlock == nil) {
        // Update cached glyphs for word wrap use
        cachedGlyphs = [NSMutableArray arrayWithArray:[textBlock glyphs]];
        return ;
    }
    
    NSMutableArray *glyphs = [self.page.textParser glyphs];
    GGlyph *prevGlyph = [self getPrevGlyph];

    if (prevGlyph) {
        CGFloat deltaX = prevGlyph.width * -1;
        [self moveGlyphsAfter:prevGlyph byDeltaX:deltaX];
    } else {
        // Update cached glyphs for word wrap use
        cachedGlyphs = [NSMutableArray arrayWithArray:[textBlock glyphs]];
        return ;
    }
    
    // Remove glyph index in front of insertion point this is prevIndex in
    // this case
    lastDeletedGlyph = prevGlyph;
    [glyphs removeObject:prevGlyph];
    [textBlock removeGlyph:prevGlyph];
    [self saveEditingGlyphs];
    insertionPointIndex--;
    if (insertionPointIndex < 0) {
        insertionPointIndex = 0;
    }
    
    // Update cached glyphs for word wrap use
    [self updateCachedGlyphs:[textBlock glyphs] removeGlyph:prevGlyph];
}

- (void)updateFontNameAndFontSize {
    int glyphIndexInLine = [textBlock getGlyphIndexInLine:insertionPointIndex];
    GGlyph *prevGlyph = [self getPrevGlyph];
    
    if (glyphIndexInLine == 0) {
        GGlyph *currentGlyph = [self getCurrentGlyph];
        // Let's update font name, and font size based on current glyph
        // if insertion point is at the beginning of line
        self.pdfFontName = [currentGlyph fontName];
        self.fontSize = [currentGlyph fontSize];
        return ;
    }
    
    if (prevGlyph != nil) {
        // Let's update font name, and font size based on previous glyph
        self.pdfFontName = [prevGlyph fontName];
        self.fontSize = [prevGlyph fontSize];
    } else {
        // If prevGlyph is nil, which means we are at the last glyph
        GGlyph *lastGlyph = [[textBlock glyphs] lastObject];
        self.pdfFontName = [lastGlyph fontName];
        self.fontSize = [lastGlyph fontSize];
    }
}

// Move glyphs after startGlyph (including startGlpyh) by delta x
- (void)moveGlyphsIncludeAfter:(GGlyph*)startGlyph byDeltaX:(CGFloat)deltaX {
    NSArray *textBlockGlyphs =  [textBlock glyphs];
    int startIndex = (int)[textBlockGlyphs indexOfObject:startGlyph];
    NSPoint startPoint = [startGlyph point];
    startPoint.x += ([startGlyph width] / 2);
    
    //NSLog(@"index: (start) %@", [startGlyph content]);
    [self moveGlyph:startGlyph byDeltaX:deltaX byDeltaY:0];
    
    int i;
    for (i = startIndex + 1; i < [textBlockGlyphs count]; i++) {
        GGlyph *g = [textBlockGlyphs objectAtIndex:i];
        NSPoint p = [g point];
        if (p.x >= startPoint.x) {
            //NSLog(@"index: %d %@", i, [g content]);
            [self moveGlyph:g byDeltaX:deltaX byDeltaY:0];
        } else if (p.x < startPoint.x) {
            break;
        }
    }
}

// Move glyphs after startGlyph (but not including startGlpyh) by delta x
- (void)moveGlyphsAfter:(GGlyph*)startGlyph byDeltaX:(CGFloat)deltaX {
    NSArray *textBlockGlyphs =  [textBlock glyphs];
    int startIndex = (int)[textBlockGlyphs indexOfObject:startGlyph];
    NSPoint startPoint = [startGlyph point];
    startPoint.x += ([startGlyph width] / 2);
    
    int i;
    for (i = startIndex + 1; i < [textBlockGlyphs count]; i++) {
        GGlyph *g = [textBlockGlyphs objectAtIndex:i];
        NSPoint p = [g point];
        if (p.x >= startPoint.x) {
            //NSLog(@"index: %d %@", i, [g content]);
            [self moveGlyph:g byDeltaX:deltaX byDeltaY:0];
        } else if (p.x < startPoint.x) {
            break;
        }
    }
}

- (void)moveGlyph:(GGlyph*)glyph byDeltaX:(CGFloat)deltaX byDeltaY:(CGFloat)deltaY {
    NSMutableArray *glyphs = [[self.page textParser] glyphs];
    int indexOfPage = (int)[glyphs indexOfObject:glyph];
    CGAffineTransform textMatrix = glyph.textMatrix;
    textMatrix.tx += deltaX;
    textMatrix.ty += deltaY;
    GGlyph *g = [glyphs objectAtIndex:indexOfPage];
    [g setTextMatrix:textMatrix];
}

- (void)setCTM:(CGAffineTransform)ctm
    textMatrix:(CGAffineTransform)textMatrix
      forGlyph:(GGlyph*)glyph {
    NSMutableArray *glyphs = [[self.page textParser] glyphs];
    int indexOfPage = (int)[glyphs indexOfObject:glyph];
    GGlyph *g = [glyphs objectAtIndex:indexOfPage];
    [g setCtm:ctm];
    [g setTextMatrix:textMatrix];
}

- (void)moveLine:(GLine*)line byDeltaY:(int)deltaY {
    NSArray *lineGlyphs =  [line glyphs];
    int i;
    for (i = 0; i < [lineGlyphs count]; i++) {
        GGlyph *glyph = [lineGlyphs objectAtIndex:i];
        [self moveGlyph:glyph byDeltaX:0.0 byDeltaY:deltaY];
    }
}

- (void)moveLinesUpwardAfter:(GLine*)currentLine {
    NSRect currentLineFrame = [currentLine frame];
    CGFloat currentMinY = NSMinY(currentLineFrame);
    NSArray *lines = [textBlock lines];
    int currentLineIndex = (int)[lines indexOfObject:currentLine];
    GLine *nextLine = [lines objectAtIndex:currentLineIndex + 1];
    if (nextLine) {
        NSRect nextLineFrame = [nextLine frame];
        CGFloat nextMinY = NSMinY(nextLineFrame);
        // NOTE: The sign of this delta should be careful
        CGFloat deltaY = nextMinY - currentMinY;
        int i;
        for (i = currentLineIndex + 1; i < [lines count]; i++) {
            GLine *line = [lines objectAtIndex:i];
            [self moveLine:line byDeltaY:deltaY];
        }
    }
}

- (void)copyPositionOfGlyph:(GGlyph*)source toGlyph:(GGlyph*)destination {
    NSArray *glyphs = [[self.page textParser] glyphs];
    int indexOfPage = (int)[glyphs indexOfObject:destination];
    GGlyph *destGlyph = [glyphs objectAtIndex:indexOfPage];
    CGAffineTransform ctm = source.ctm;
    CGAffineTransform textMatrix = source.textMatrix;
    [destGlyph setCtm:ctm];
    [destGlyph setTextMatrix:textMatrix];
}

- (void)doWordWrap {
    GTextBlock *tb = [self getTextBlockByCachedGlyphs];
    NSArray *words = [tb words];
    //prettyLogForWords(words);
    
    wordWrapCTM = ctm;
    wordWrapTextMatrix = textMatrix;
    widthLeft = [self getEditorWidth];
    GGlyph *firstGlyph = [[tb glyphs] firstObject];
    editorHeight = [firstGlyph height];
    lastWrapGlyph = nil;
    wordWrappedLines = [NSMutableArray array];
    currentWordWrapLine = [GWrappedLine create];
    for (GWord *word in words) {
        CGFloat wordWidth = [word getWordWidth];
        if (wordWidth >= [self getEditorWidth] && widthLeft > 0) {
            // In case next word width is bigger than editor width and there is room
            // in current line (that is widthLeft > 0)
            // Need line break in [self wrapWord:]
            wordWidth = [self wrapWord:word];
            widthLeft -= wordWidth;
        } else if (widthLeft - wordWidth >= 0) {
            wordWidth = [self wrapWord:word];
            widthLeft -= wordWidth;
        } else {
            GGlyph *glyph = [[word glyphs] firstObject];
            if (!isWhiteSpaceGlyph(glyph)) {
                [self lineBreak];
                // Add new line to word wrapped lines array, and create a new line
                [wordWrappedLines addObject:currentWordWrapLine];
                currentWordWrapLine = [GWrappedLine create];
            }
            wordWidth = [self wrapWord:word];
            widthLeft -= wordWidth;
        }
    }
    
    // Add the last line because we don't have a line break at the end
    // If there is any glyph in last line
    if ([[currentWordWrapLine glyphs] count] > 0) {
        [wordWrappedLines addObject:currentWordWrapLine];
    }
    everWrapWord = YES;
    // Test wrapping result
    //tb = [self getTextBlockByCachedGlyphs];
    //words = [tb words];
    //prettyLogForWords(words);
}

- (CGFloat)wrapWord:(GWord*)w {
    CGFloat totalWidth = 0.0;
    CGFloat localWidthLeft = widthLeft;
    for (GGlyph *g in [w glyphs]) {
        CGFloat glyphWidth = [g width];
        CGFloat width;
        if (isReturnGlyph(g)) { // Manual line break
            /*
             * If '\n' is at the end of text, we do line break before
             * wrap glyph, to make sure we have a new line to enter text
             */
            GTextBlock *tb = [self getTextBlockByCachedGlyphs];
            NSArray *glyphs = [tb glyphs];
            if ([[glyphs lastObject] isEqualTo:g]) {
                [self lineBreak];
            }
            // Add new line to word wrapped lines array, and create a new line
            [currentWordWrapLine addGlyph:g];
            [wordWrappedLines addObject:currentWordWrapLine];
            currentWordWrapLine = [GWrappedLine create];
            totalWidth = 0.0;
            localWidthLeft = [self getEditorWidth];
            width = [self wrapGlyph:g];
            totalWidth += width;
            
            // Line break delay to here, to make sure \n is at the end of
            // line before line breaks
            [self lineBreak];
        } else if (localWidthLeft - glyphWidth >= 0) {
            width = [self wrapGlyph:g];
            totalWidth += width;
            [currentWordWrapLine addGlyph:g];
        } else {
            // NOTE: We can only do word wrapping in this?
            //       Means it's start word wrapping in glyph wide.
            //       TODO: Consider as an option later
            if (!isWhiteSpaceGlyph(g)) {
                [self lineBreak];
                // Add new line to word wrapped lines array, and create a new line
                [wordWrappedLines addObject:currentWordWrapLine];
                currentWordWrapLine = [GWrappedLine create];
            }
            totalWidth = 0.0;
            localWidthLeft = [self getEditorWidth];
            width = [self wrapGlyph:g];
            totalWidth += width;
            [currentWordWrapLine addGlyph:g];
        }
        localWidthLeft -= width;
    }
    return totalWidth;
}

- (CGFloat)wrapGlyph:(GGlyph*)g {
    NSMutableArray *glyphs = [[self.page textParser] glyphs];
    if (![glyphs containsObject:g]) {
        // urh, this should never happens
        return 0.0;
    }
    
    [self setCTM:wordWrapCTM textMatrix:wordWrapTextMatrix forGlyph:g];
    wordWrapCTM = [g ctm];
    // Take account for glyph delta in operator in "TJ"
    wordWrapTextMatrix.tx += [g width];
    lastWrapGlyph = g;
    return [g width];
}

- (void)lineBreak {
    if (lastWrapGlyph) {
        wordWrapCTM = ctm;
        //GWrappedLine *currentLine = [self getCurrentWrappedLine];
        //GGlyph *firstGlyph = [[currentLine glyphs] firstObject];
        CGAffineTransform lastTextMatrix = [lastWrapGlyph textMatrix];
        wordWrapTextMatrix = textMatrix;
        // Now, even we don't add 2 points to the deltaY, it will also work,
        // since we have updated compareGlyphs().
        //
        // Note: We have updated makeReadOrderGlyphs (actually it's compareGlyphs())
        //       to make it more robust for uneven heights of glyphs.
        // TODO: Better calculatation for delta y by the height
        //       (height = descent of lastWrapGlyp + ascent of next glyph) of
        //       next glyph after line break.
        CGFloat deltaY = [lastWrapGlyph height] + 1; // Plus 1 to make 1 point line margin
        
        // Check the sign of d component of ctm, and decide the sing of deltaY
        int sign = signOfCGFloat(wordWrapCTM.d);
        deltaY = -1 * sign * deltaY;
        wordWrapTextMatrix.ty = lastTextMatrix.ty + deltaY;
        widthLeft = [self getEditorWidth];
        editorHeight += deltaY;
    } else {
        //
        // We currently don't handle if last wrapped glyph is nil
        // NOTE: We always get last wrap glyph even we do line break at the
        // start of text, in this case, the last wrapped glyph in a '\n' glyph
        //
    }
}

- (void)updateCachedGlyphs:(NSArray*)glyphs newGlyph:(GGlyph*)newGlyph {
    cachedGlyphs = [NSMutableArray arrayWithArray:glyphs];
    [cachedGlyphs addObject:newGlyph];
}

- (void)updateCachedGlyphs:(NSArray*)glyphs removeGlyph:(GGlyph*)glyphToRemove {
    cachedGlyphs = [NSMutableArray arrayWithArray:glyphs];
    [cachedGlyphs removeObject:glyphToRemove];
}

#pragma Insertion point manage
- (void)moveInsertionPointDown {
    if (!everWrapWord) {
        int currentLineIndex = [textBlock getLineIndex:insertionPointIndex];
        if (currentLineIndex != -1) { // No errors
            if (currentLineIndex + 1 <= [[textBlock lines] count] - 1) {
                int nextLineIndex = currentLineIndex + 1;
                GLine *nextLine = [[textBlock lines] objectAtIndex:nextLineIndex];
                int glyphIndexInCurrentLine = [textBlock getGlyphIndexInLine:insertionPointIndex];
                
                
                if (glyphIndexInCurrentLine >= (int)[[nextLine glyphs] count]) {
                    insertionPointIndex = (int)[glyphs count];
                } else {
                    int glyphIndexInNextLine = glyphIndexInCurrentLine;
                    GGlyph *currentGlyph = [[nextLine glyphs] objectAtIndex:glyphIndexInNextLine];
                    insertionPointIndex = currentGlyph.indexOfBlock;
                }
            }
        } else if (insertionPointIndex == [glyphs count]) {
            // No need to handle insertion point in last position, because we
            // have no next line to move to
        }
    } else {
        GWrappedLine *currentLine = [self getCurrentWrappedLine];
        GWrappedLine *nextLine = [self getNextWrappedLine];
        if (nextLine) {
            GGlyph *currentGlyph = [self getCurrentWrappedGlyph];
            if (currentGlyph == nil) {
                // This means we are moving down, and also we are at the end of
                // text, do nothing is a right choice.
            } else {
                int indexOfLine = [currentLine indexforGlyph:currentGlyph];
                if (indexOfLine > [[nextLine glyphs] count] - 1) {
                    indexOfLine = (int)[[nextLine glyphs] count] - 1;
                }
                GGlyph *glyphInNextLine = [nextLine getGlyphByIndex:indexOfLine];
                insertionPointIndex = [self indexOfWrappedGlyph:glyphInNextLine];
            }
        }
    }
}

- (void)moveInsertionPointUp {
    if (!everWrapWord) {
        int currentLineIndex = [textBlock getLineIndex:insertionPointIndex];
        // Curernt line is valid, and insertion point is not at the end of text block
        if (currentLineIndex != -1 && insertionPointIndex != [glyphs count]) {
            if (currentLineIndex - 1 >= 0) {
                int previousLineIndex = currentLineIndex - 1;
                GLine *prevLine = [[textBlock lines] objectAtIndex:previousLineIndex];
                int glyphIndexInCurrentLine = [textBlock getGlyphIndexInLine:insertionPointIndex];
                if (glyphIndexInCurrentLine > (int)[[prevLine glyphs] count] - 1) {
                    glyphIndexInCurrentLine = (int)[[prevLine glyphs] count] - 1;
                }
                int glyphIndexInPrevLine = glyphIndexInCurrentLine;
                GGlyph *currentGlyph = [[prevLine glyphs] objectAtIndex:glyphIndexInPrevLine];
                insertionPointIndex = currentGlyph.indexOfBlock;
            }
        } else if (insertionPointIndex == [glyphs count]) { // Edge case: insertion point is at the end of text
            int currentLineIndex = [textBlock getLineIndex:insertionPointIndex - 1];
            if (currentLineIndex != -1) { // No errors
                if (currentLineIndex - 1 >= 0) {
                    int previousLineIndex = currentLineIndex - 1;
                    GLine *prevLine = [[textBlock lines] objectAtIndex:previousLineIndex];
                    int glyphIndexInCurrentLine = [textBlock getGlyphIndexInLine:insertionPointIndex-1];
                    if (glyphIndexInCurrentLine > (int)[[prevLine glyphs] count] - 1) {
                        glyphIndexInCurrentLine = (int)[[prevLine glyphs] count] - 1;
                    }
                    int glyphIndexInPrevLine = glyphIndexInCurrentLine;
                    GGlyph *currentGlyph = [[prevLine glyphs] objectAtIndex:glyphIndexInPrevLine];
                    insertionPointIndex = currentGlyph.indexOfBlock + 1;
                }
            }
        }
    } else {
        GWrappedLine *currentLine = [self getCurrentWrappedLine];
        GWrappedLine *prevLine = [self getPrevWrappedLine];
        if (prevLine) {
            GGlyph *currentGlyph = [self getCurrentWrappedGlyph];
            int indexOfLine = [currentLine indexforGlyph:currentGlyph];
            // We are at the end of text to get -1 returned. Just put index of
            // line to last index.
            if (indexOfLine == -1) {
                indexOfLine = (int)[[currentLine glyphs] count] - 1;
            }
            if (indexOfLine > [[prevLine glyphs] count] - 1) {
                indexOfLine = (int)[[prevLine glyphs] count] - 1;
            }
            GGlyph *glyphInNextLine = [prevLine getGlyphByIndex:indexOfLine];
            insertionPointIndex = [self indexOfWrappedGlyph:glyphInNextLine];
         }
    }
}

#pragma GWrappedLine functions
- (GGlyph*)getCurrentWrappedGlyph {
    int index = insertionPointIndex;
    
    // We are at the end of text, so we return nil;
    if (index > [glyphs count] - 1) {
        return nil;
    }
    
    int i = 0;
    for (GWrappedLine *l in wordWrappedLines) {
        for (GGlyph *g in [l glyphs]) {
            if (i == index) {
                return g;
            }
            i++;
        }
    }
    
    // No current glyph found, uh, this should happen at the top, we have
    // return nil already.
    return nil;
}

- (GWrappedLine*)getCurrentWrappedLine {
    int index = insertionPointIndex;
    
    // We are at the end of text, so we return last
    // line.
    if (index > [glyphs count] - 1) {
        return [wordWrappedLines lastObject];
    }
    
    int i = 0;
    GGlyph *glyph;
    for (GWrappedLine *l in wordWrappedLines) {
        for (GGlyph *g in [l glyphs]) {
            glyph = g; // To make compiler happy, not to show unused variable warning.
            if (i == index) {
                return l;
            }
            i++;
        }
    }
    
    // No current line found, uhh, this shoud never happen.
    return nil;
}

- (GWrappedLine*)getPrevWrappedLine {
    GWrappedLine *currentLine = [self getCurrentWrappedLine];
    int indexOfCurrentLine = (int)[wordWrappedLines indexOfObject:currentLine];
    if (indexOfCurrentLine >= 1) {
        return [wordWrappedLines objectAtIndex:indexOfCurrentLine - 1];
    }
    return nil;
}

- (GWrappedLine*)getNextWrappedLine {
    GWrappedLine *currentLine = [self getCurrentWrappedLine];
    int linesCount = (int)[wordWrappedLines count];
    int indexOfCurrentLine = (int)[wordWrappedLines indexOfObject:currentLine];
    if (indexOfCurrentLine + 1 <= linesCount - 1) {
        return [wordWrappedLines objectAtIndex:indexOfCurrentLine + 1];
    }
    return nil;
}

- (int)indexOfWrappedGlyph:(GGlyph*)glyph {
    int index = 0;
    for (GWrappedLine *l in wordWrappedLines) {
     for (GGlyph *g in [l glyphs]) {
         if ([g isEqualTo:glyph]) {
             return index;
         }
         index++;
     }
    }
    // No glyph found, return -1
    return -1;
}

- (CGFloat)getFontSizeForEditor {
    GGlyph *prevGlyph = [self getPrevGlyph];
    if (prevGlyph){
        NSSize size = NSMakeSize([prevGlyph fontSize], 0);
        size = CGSizeApplyAffineTransform(size, [prevGlyph textMatrix]);
        return size.width;
    }
    return -1;
}

- (NSString*)getPDFFontNameForEditor {
    GGlyph *prevGlyph = [self getPrevGlyph];
    NSString *fontName;
    if (!prevGlyph){
        prevGlyph = [[textBlock glyphs] lastObject];
    }
    
    if (prevGlyph){
        // Debug purpose
        // NSLog(@"[Debug] Added fonts: %@, font tag: %@", self.page.addedFonts, [prevGlyph fontName]);
        for (NSString *fontTag in [self.page.addedFonts allKeys]) {
            NSString *fontKey = [NSString stringWithFormat:@"%@-%f", [prevGlyph fontName], 1.0];
            if ([fontTag isEqualToString:fontKey]) {
                fontName = [[self.page.addedFonts objectForKey:fontTag] fontName];
                return fontName;
            }
        }
        fontName = [self.page getFontNameByFontTag:[prevGlyph fontName]];
        return fontName;
    }
    return nil;
}

- (BOOL)isCurrentFontMatchesSelected {
    BOOL result = NO;
    NSString *pdfFontName = [self getPDFFontNameForEditor];
    NSString *familyName = getFontNameFromSubset(pdfFontName);
    NSString *style = getFontStyleFromSubset(pdfFontName);
    
    PEPSideView *sideView = [self getSideView];
    NSString *selectedFamily = [sideView selectedFamily];
    NSString *selectedStyle = [sideView selectedStyle];
    if ([familyName isEqualToString:selectedFamily] &&
        [style isEqualToString:selectedStyle]) {
        result = YES;
    }
    return result;
}

- (PEPSideView*)getSideView {
    PEPSideView *sideView = [(PEPWindow*)self.page.doc.window sideView];
    return sideView;
}

- (void)stopBlinkTimer {
    [blinkTimer invalidate];
    blinkTimer = nil;
}
@end

