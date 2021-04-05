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
        [textParser setUseTJTexts:NO];
        [textParser setGlyphs:glyphs];
        GTextBlock *tb = [textParser mergeLinesToTextblock];
        return tb;
    }
}

- (GTextBlock*)getTextBlockByCachedGlyphs {
    GTextParser *textParser = [GTextParser create];
    [textParser setUseTJTexts:NO];
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
    // Plus 1px to prevent error after word wrapping
    return editorWidth + 1;
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
        
        [g setPage:self.page];
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
    
    [g setPage:self.page];
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
    NSPoint startPoint = [startGlyph frame].origin;
    startPoint.x += ([startGlyph width] / 2);
    
    //NSLog(@"index: (start) %@", [startGlyph content]);
    [self moveGlyph:startGlyph byDeltaX:deltaX byDeltaY:0];
    
    int i;
    for (i = startIndex + 1; i < [textBlockGlyphs count]; i++) {
        GGlyph *g = [textBlockGlyphs objectAtIndex:i];
        NSPoint p = [g frame].origin;
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
    NSPoint startPoint = [startGlyph frame].origin;
    startPoint.x += ([startGlyph width] / 2);
    
    int i;
    for (i = startIndex + 1; i < [textBlockGlyphs count]; i++) {
        GGlyph *g = [textBlockGlyphs objectAtIndex:i];
        NSPoint p = [g frame].origin;
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
    NSMutableArray *textParserGlyphs = [[self.page textParser] glyphs];
    int indexOfPage = (int)[textParserGlyphs indexOfObject:glyph];
    GGlyph *g = [textParserGlyphs objectAtIndex:indexOfPage];
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
    /*NSArray *lines1 = [textBlock lines];
    printf("--Lines before wordWrapping: %d lines\n", (int)[lines1 count]);
    for (GLine *line in lines1) {
        NSLog(@"%@", [line lineString]);
    }
    printf("===END===\n");
    prettyLogForWords([textBlock words]);
    */
    NSMutableArray *lines = [self wordWrapToLines];
    
    // Test: log out lines after word warpping
    /*printf("++Lines after wordWrapping: %d lines\n", (int)[lines count]);
    for (GLine *line in lines) {
        NSLog(@"%@", [line lineString]);
    }
    printf("===END===\n");
    */
    [self leftAlignLines:lines];
    [textBlock setLines:lines];
}

/*
 * This method do word wrapping and create final result lines, but
 * all glyphs in lines do not update it's text matrix, we do it in
 * align methods, like leftAlignLines, rightAlignLines,
 * centerAlignLines, leftRightAlignLines.
 */
- (NSMutableArray*)wordWrapToLines {
    textBlock = [self getTextBlockByCachedGlyphs];
    NSArray *words = [textBlock words];
    NSArray *originalLines = [textBlock lines];
    
    NSMutableArray *lines = [NSMutableArray array];
    CGFloat widthLeft = [self getEditorWidth];
    GLine *currentLine = [GLine create];
    for (GWord *word in words) {
        CGFloat wordWidth = [word getWordWidth];
        CGFloat wordDistance = [word wordDistance];
        if (wordDistance == kNoWordDistance) {
            // TODO: Change word distance to the value of width of one `space`,
            //       we eval this `space` width to be the first glyph of current
            //       word.
            wordDistance = 0;
            [word setWordDistance:wordDistance];
        }
        
        // Choose if to line break or not
        if (widthLeft - wordWidth - wordDistance >= 0) {
            [currentLine addWord:word];
            widthLeft -= (wordWidth + wordDistance);
        } else { // Do line break by creating a new line as current line
            CGAffineTransform startTextMatrix = [self getStartTextMatrix:lines
                                                           originalLines:originalLines];
            [currentLine setStartTextMatrix:startTextMatrix];
            [lines addObject:currentLine];
            
            currentLine = [GLine create];
            [word setWordDistance:kNoWordDistance];
            [currentLine addWord:word];
            
            // Update widthLeft, don't need to care about word distance,
            // we are at the beginning of line
            widthLeft = [self getEditorWidth];
            widthLeft -= wordWidth;
        }
    }
    
    // Add remaining current line in case it's not an empty line
    if ([[currentLine words] count] > 0) {
        CGAffineTransform startTextMatrix = [self getStartTextMatrix:lines
                                                       originalLines:originalLines];
        [currentLine setStartTextMatrix:startTextMatrix];
        [lines addObject:currentLine];
    }
    return lines;
}

- (void)leftAlignLines:(NSArray*)lines {
    for (GLine *l in lines) {
        CGAffineTransform textMatrix = [l startTextMatrix];
        for (GWord *w in [l words]) {
            textMatrix = [self updateTextMatrixForGlyphsInWord:w withTextMatrix:textMatrix];
        }
    }
}

- (CGAffineTransform)updateTextMatrixForGlyphsInWord:(GWord*)word
                                      withTextMatrix:(CGAffineTransform)startTextMatrix {
    CGAffineTransform ctm = [[[word glyphs] firstObject] ctm];
    CGAffineTransform ctmInverted = CGAffineTransformInvert(ctm);
    CGFloat wordDistance = [word wordDistance];
    if (wordDistance == kNoWordDistance) {
        wordDistance = 0.0;
    }
    CGSize size = NSMakeSize(wordDistance, 0);
    size = CGSizeApplyAffineTransform(size, ctmInverted);
    
    // Word distance now is in text space, after applied by inveted CTM
    wordDistance = size.width;
    CGAffineTransform textMatrix = startTextMatrix;
    textMatrix.tx += wordDistance;
    GGlyph *prevGlyph = nil;
    
    // Text matrix of previous glyph before changing it's text matrix
    CGAffineTransform prevTextMatrix = CGAffineTransformIdentity;
    
    for (GGlyph *glyph in [word glyphs]) {
        if ([[word glyphs] indexOfObject:glyph] == 0) { // first glyph, just set text matrix
            prevTextMatrix = [glyph textMatrix];
            [glyph setTextMatrix:textMatrix];
            
            // Add glyph width to text matrix
            CGFloat width = [glyph width];
            textMatrix.tx += width;
            prevGlyph = glyph;
        } else {
            // Add glyph distance
            /*
             * Calculate glyph distance in text space.
             */
            CGAffineTransform tm1 = prevTextMatrix;
            tm1.tx += [prevGlyph width];
            CGAffineTransform tm2 = [glyph textMatrix];
            CGFloat glyphDistance = tm2.tx - tm1.tx;
            textMatrix.tx += glyphDistance;
            
            // Saved current text matrix as prevTextMatrix and set text matrix
            prevTextMatrix = [glyph textMatrix];
            [glyph setTextMatrix:textMatrix];
            
            // After that, just add glyph width to text matrix
            CGFloat width = [glyph width];
            textMatrix.tx += width;
            prevGlyph = glyph;
        }
    }
    return textMatrix;
}


- (CGAffineTransform)getStartTextMatrix:(NSArray*)lines originalLines:(NSArray*)originalLines {
    /*
     * Get startTextMatrix of original line.
     * If line index is out of bound of original lines, it's set to
     * 1) startTextMatrix = (startTextMatrix of previous line) and
     * 2) startTextMatrix.ty += delta of last two lines textMatrix
     */
    int lineIndex = (int)[lines count];
    CGAffineTransform startTextMatrix;
    if (lineIndex <= [originalLines count] - 1) { // line index is in the bound of original lines
        GLine *originalLine = [originalLines objectAtIndex:lineIndex];
        startTextMatrix = [originalLine startTextMatrix];
    } else { // line index is out of bound of original lines
        startTextMatrix = [[originalLines lastObject] startTextMatrix];
        CGAffineTransform ctm = [[[[originalLines lastObject] glyphs] firstObject] ctm];
        CGAffineTransform ctmInverted = CGAffineTransformInvert(ctm);
        CGFloat deltaY = 0;
        if ([originalLines count] >= 2) { // We need last two lines to get the delta y
            GLine *l1 = [originalLines objectAtIndex:[originalLines count] - 2];
            GLine *l2 = [originalLines lastObject];
            CGRect f1 = [l1 frame];
            CGRect f2 = [l2 frame];
            f1 = CGRectApplyAffineTransform(f1, ctmInverted);
            f2 = CGRectApplyAffineTransform(f2, ctmInverted);
            deltaY = f2.origin.y - f1.origin.y;
        } else { // If there are only one line in original lines, we just get the line height as delta y
            GLine *lastLine = [originalLines lastObject];
            CGRect f = [lastLine frame];
            deltaY = f.size.height * -1;
        }
        startTextMatrix.ty += deltaY;
    }
    return startTextMatrix;
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
}

- (void)moveInsertionPointUp {
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
        for (NSString *fontKey in [self.page.addedFonts allKeys]) {
            NSLog(@"font key: %@ font name in prevGlyph: %@", fontKey, [prevGlyph fontName]);
            NSString *fontName = [[fontKey componentsSeparatedByString:@"~"] firstObject];
            if ([fontName isEqualToString:[prevGlyph fontName]]) {
                fontName = [[self.page.addedFonts objectForKey:fontKey] fontName];
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

/*
 * Because we can not use TJTexts to make read order glyphs, we just broke the TJ text structures
 * by adding new glyphs, so we build and cache text block without using TJTexts.
 */
- (void)dealloc {
    [self.page.textParser setCached:NO];
    [self.page.textParser setUseTJTexts:NO];
    
    // TODO: This make exiting text editor laggy
    [self.page.textParser makeTextBlocks];
}
@end

