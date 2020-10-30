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
#import "GDocument.h"
#import "GMisc.h"
#import "GConstants.h"
#import "GBinaryData.h"
#import "GTextParser.h"

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
    textBlock = tb;
    insertionPointIndex = 0;
    // Update font name, font size
    [self updateFontNameAndFontSize];
    self.drawInsertionPoint = YES;
    self.isEditing = NO;
    self.firstUsed = YES;
    self.editingGlyphs = [NSMutableArray array];
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

- (void)redraw {
    GDocument *doc = (GDocument*)[(GPage*)self.page doc];
    [doc setNeedsDisplay:YES];
}

- (void)drawInsertionPoint:(CGContextRef)context {
    NSRect rect = [self getInsertionPoint];
    NSPoint start = NSMakePoint(NSMinX(rect), NSMinY(rect));
    NSPoint end = NSMakePoint(NSMinX(rect), NSMaxY(rect));
    CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);
    CGContextSetLineWidth(context, 1.0 / (kScaleFactor));
    CGContextMoveToPoint(context, (int)(start.x) + 0.5, (int)(start.y) - 0.5);
    CGContextAddLineToPoint(context, (int)(end.x) + 0.5, (int)(end.y) - 0.5);
    CGContextStrokePath(context);
}

- (void)draw:(CGContextRef)context {
    textBlock = [self getTextBlock];
    
    // Draw text editor border with 1 pixel width;
    NSRect frame = [self enlargedFrame];
    frame = NSInsetRect(frame, 0.5, 0.5);
    CGContextSetLineWidth(context, 1.0 / (kScaleFactor));
    CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
    CGContextStrokeRect(context, frame);
    
    if (self.drawInsertionPoint) {
        [self drawInsertionPoint:context];
    }
}

- (NSRect)frame {
    if (textBlock == nil) {
        return firstGlyphFrame;
    }
    
    NSArray *glyphs = [textBlock glyphs];
    
    // Update firstGlyphFrame daynamically
    if ([glyphs count] >= 1) { // if we have at least one glyph
        GGlyph *firstGlyph = [glyphs firstObject];
        firstGlyphFrame = [firstGlyph frame];
    }
    return [textBlock frame];
}

- (NSRect)enlargedFrame {
    return NSInsetRect([self frame], -3, -3);
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
    } else if (keyCode == kRightArrow) {
        if (insertionPointIndex + 1 <= [glyphs count]) {
            insertionPointIndex++;
        }
        [self updateFontNameAndFontSize];
    } else if (keyCode == kUpArrow) {
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
        [self updateFontNameAndFontSize];
    } else if (keyCode == kDownArrow) {
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
        [self updateFontNameAndFontSize];
    } else {
        NSString *ch =[event characters];
        unichar key = [ch characterAtIndex:0];
        if(key == NSDeleteCharacter) {
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
        }
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
}

/**
 * Think through insertion point management carefully, it's just complex to take
 * edge cases into account.
 *
 * For example: "PDF |", We are in | postion, and delete all of that line,
 * now is "|", and insert 'A' (it use last deleted glyph to create A glyphp),
 * it become "A|", and insert 'B', in this insert, we need to both think about
 * insertion point is both in last postion of text block, and last position of
 * line. Which means curerent glyph is nil, so that current line will return nil.
 */

- (void)insertChar:(NSString *)ch font:(NSFont*)font {
    NSMutableArray *glyphs = [self.page.textParser glyphs];
    GGlyph *glyphNeeded;
    
    //
    // If no text in text editor, we insert based on the last deleted glyph
    //
    if (textBlock == nil) {
        glyphNeeded = lastDeletedGlyph;
        
        CGAffineTransform ctm = glyphNeeded.ctm;
        CGAffineTransform tm = glyphNeeded.textMatrix;
        NSString *fontName = glyphNeeded.fontName;
        CGFloat fontSize = glyphNeeded.fontSize;
        
        GGlyph *g = [GGlyph create];
        [g setContent:ch];
        [g setCtm:ctm];
        [g setTextMatrix:tm];
        [g setFontName:fontName];
        [g setFontSize:fontSize];
        [glyphs addObject:g]; // Add this new glyph at the end

        // Add the new glyph index to text editor's editing glyphs
        [self addGlyphIndexToEditingGlyphs:(int)[glyphs count] - 1];
        insertionPointIndex++;
        return ;
    }
    
    GGlyph *currentGlyph = [self getCurrentGlyph];
    GGlyph *prevGlyph = [self getPrevGlyph];
    
    int currentIndexInLine;
    GLine *currentLine;
    NSArray *lineGlyphs;
    
    if (currentGlyph == nil) {
        // It happens that insertion point is at both at the last position line and text block
        currentIndexInLine = [textBlock getGlyphIndexInLine:insertionPointIndex-1];
        currentLine = [textBlock getLineByGlyph:prevGlyph];
        lineGlyphs = [currentLine glyphs];
    } else {
        currentIndexInLine = [textBlock getGlyphIndexInLine:insertionPointIndex];
        currentLine = [textBlock getLineByGlyph:currentGlyph];
        lineGlyphs = [currentLine glyphs];
    }


    if (currentIndexInLine == 0 && currentGlyph != nil) {
        GGlyph *firstGlyphInLine = [lineGlyphs firstObject];
        glyphNeeded = firstGlyphInLine;
    } else if (prevGlyph != nil) {
        glyphNeeded = prevGlyph;
    }
    
    // Debug
    //NSLog(@"line: %@ glyphNeeded %@ current: %@", [currentLine lineString], [glyphNeeded content], [currentGlyph content]);
    
    CGAffineTransform ctm = glyphNeeded.ctm;
    CGAffineTransform tm = glyphNeeded.textMatrix;
    NSString *fontName = glyphNeeded.fontName;
    CGFloat fontSize = glyphNeeded.fontSize;
    CGFloat glyphWidth = glyphNeeded.width;
    
    // Current position at line > 0.
    // At last postion of text block (currentGlyph == nil) also means position > 0
    if (currentIndexInLine > 0 || currentGlyph == nil) {
        tm.tx += glyphWidth;
    }
    
    GGlyph *g = [GGlyph create];
    [g setContent:ch];
    [g setCtm:ctm];
    [g setTextMatrix:tm];
    [g setFontName:fontName];
    [g setFontSize:fontSize];
    [glyphs addObject:g]; // Add this new glyph at the end

    // Add the new glyph index to text editor's editing glyphs
    [self addGlyphIndexToEditingGlyphs:(int)[glyphs count] - 1];
    
    // We don't need to care about later glyphs, since insertion point is
    // at the end of text block
    if (insertionPointIndex > [[textBlock glyphs] count] - 1) {
        insertionPointIndex++;
        return ;
    }
    
    CGFloat hAdvance = 0;
    NSSize s;
    hAdvance = getGlyphAdvanceForFont(ch, font);

    s = NSMakeSize(hAdvance, 0);
    s = CGSizeApplyAffineTransform(s, tm);
    int deltaX = s.width;
    // Move glyphs after current glyph afterwards in current line
    [self moveGlyphsIncludeAfter:currentGlyph byDeltaX:deltaX inLine:currentLine];
    
    insertionPointIndex++;
}

- (void)insertChar:(NSString *)ch {
    if (self.isEditing) return ;
    self.isEditing = YES;
    // Test insert character into text editor
    // Fixme: use any font here, font is not useful by now
    NSString *fontName = [self pdfFontName];
    CGFloat fontSize = [self fontSize];
    NSFont *font = [NSFont fontWithName:@"Gill Sans" size:fontSize];
    [self insertChar:ch font:font];
    [self.page buildPageContent];
    [self.page addFont:font withPDFFontName:fontName];
    [self.page addPageStream];
    [self.page incrementalUpdate];
    [self.page setNeedUpdate:YES];
    self.isEditing = NO;
}

- (GGlyph*)getCurrentGlyph {
    GGlyph *currentGlyph;
    int index = insertionPointIndex;
    if (index >= 0 && index <= [[textBlock glyphs] count] - 1) {
        currentGlyph = [[textBlock glyphs] objectAtIndex:index];
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
    return nil;
}

- (void)deleteCharacter {
    if (self.isEditing) return ;
    self.isEditing = YES;
    // Font size will change between deleteing and adding character
    // So we also add new font here to workaround it.
    // Fixme: Orignal subset of Gill Sans in PDF dose not contains some
    //        glyphs in the editor, becasue we always remove previous upadte
    //        in [GPage incrementalUpdate], so news glyphs will fallback to
    //        system fonts, that would cause the font size change.
    NSFont *font = [NSFont fontWithName:@"Gill Sans" size:1.0];
    [self.page addFont:font withPDFFontName:@"TT1"];
    [self deleteCharacterInInsertionPoint];
    [self.page buildPageContent];
    [self.page addPageStream];
    [self.page incrementalUpdate];
    [self.page setNeedUpdate:YES];
    self.isEditing = NO;
}

- (void)deleteCharacterInInsertionPoint {
    // No text in text editor
    if (textBlock == nil) {
        return ;
    }
    
    NSMutableArray *glyphs = [self.page.textParser glyphs];
    GGlyph *currentGlyph = [self getCurrentGlyph];
    GGlyph *prevGlyph = [self getPrevGlyph];

    GGlyph *glyphNeeded;

    int currentIndexInLine;
    GLine *prevLine;
    GLine *currentLine;
    NSArray *lineGlyphs;
    
    BOOL needMoveForward = YES;
    
    CGFloat glyphWidth;
    int deltaX;
    
    if (currentGlyph == nil) {
         // It happens that insertion point is at the last of both line and text block
         currentIndexInLine = [textBlock getGlyphIndexInLine:insertionPointIndex-1];
         currentLine = [textBlock getLineByGlyph:prevGlyph];
         lineGlyphs = [currentLine glyphs];
     } else {
         currentIndexInLine = [textBlock getGlyphIndexInLine:insertionPointIndex];
         currentLine = [textBlock getLineByGlyph:currentGlyph];
         lineGlyphs = [currentLine glyphs];
     }

 
    // Insertion point is at the end of text blocks
    if (insertionPointIndex == [[textBlock glyphs] count]){
        glyphNeeded = prevGlyph;
    } else if (currentIndexInLine == 0) {
        prevLine = [textBlock getLineByGlyph:prevGlyph];
        if (prevLine == nil) {
            return ;
        } else {
            // Previous glyph should be last glyph of previous line
            prevGlyph = [[prevLine glyphs] lastObject];
            glyphNeeded = currentGlyph;
            needMoveForward = NO;
        }
    }else if (prevGlyph != nil) {
        glyphNeeded = prevGlyph;
    }

    // Debug
    //NSLog(@"line: %@ glyphNeeded %@ current: %@", [currentLine lineString], [glyphNeeded content], [currentGlyph content]);
    
    glyphWidth = glyphNeeded.width;
   
    deltaX = glyphWidth * -1;

    if (currentGlyph && !needMoveForward &&
        [[prevLine glyphs] count] > 1 /* We don't move glyphs after forwards, while
                                       * we are at the begining of line, and previous line
                                       * has more than 1 glyphs. We move later lines upward while
                                       * previous glyphs equals to 1 later (empty line after deleting).
                                       * [[prevLine glyphs] count] == 1
                                       */){
        deltaX = 0;
    }
    
    // NOTE: We can not delete a whole line while we are in this line, because we
    //       can only delete last glyph while we are in the beginning of next line;
    //       Example:
    //       "Editing"
    //       "|Program", like here.
    // NOTE: If there is only one glyph in prev line, after deleting current glyph
    //       There is no glyphs in prev line, what we do here is move after lines
    //       upwards
    // NOTE: This condiction will only met if we delete from next line. See below.
    //       Example: "g"
    //               "|Program"
    //       After deleting in |, we get.
    //               "|P"
    //               "rogram"
    //       What we do here is let it become below after deleting
    //               "|Program"
    //       So we will never delete a whole line which has 0 glyphs
    if (currentIndexInLine == 0) {
        if (prevLine){ // we have previous line
            // Also previous has only one glyph, so let's move up lines after
            // prev line.
            if ([[prevLine glyphs] count] == 1) {
                [self moveLinesUpwardAfter:prevLine];
                // In this case we should not move glyphs after by deltaX,
                // So we make deltaX to be 0;
                deltaX = 0;
            }
        }
    }
    
    [self moveGlyphsAfter:glyphNeeded byDeltaX:deltaX inLine:currentLine];
    
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
        NSLog(@"Text Editor font name: %@ font size: %f glyph: %@", self.pdfFontName, self.fontSize, [currentGlyph content]);
        return ;
    }
    
    if (prevGlyph != nil) {
        // Let's update font name, and font size based on previous glyph
        self.pdfFontName = [prevGlyph fontName];
        self.fontSize = [prevGlyph fontSize];
        NSLog(@"Text Editor font name: %@ font size: %f glyph: %@", self.pdfFontName, self.fontSize, [prevGlyph content]);
    }
}

// Move glyphs after startGlyph (including startGlpyh) by delta x in line
- (void)moveGlyphsIncludeAfter:(GGlyph*)startGlyph byDeltaX:(CGFloat)deltaX inLine:(GLine*)line {
    NSMutableArray *glyphs = [[self.page textParser] glyphs];
    NSArray *lineGlyphs =  [line glyphs];
    int i;
    for (i = 0; i < [lineGlyphs count]; i++) {
        GGlyph *tmp = [lineGlyphs objectAtIndex:i];
        if (tmp.indexOfBlock >= startGlyph.indexOfBlock) {
            NSLog(@"index: %d %@", i, [tmp content]);
            GGlyph *laterGlyph = [lineGlyphs objectAtIndex:i];
            
            int indexOfPage = (int)[glyphs indexOfObject:tmp];
            CGAffineTransform textMatrix = laterGlyph.textMatrix;
            textMatrix.tx += deltaX;
            laterGlyph = [glyphs objectAtIndex:indexOfPage];
            [laterGlyph setTextMatrix:textMatrix];
        }
    }
}

// Move glyphs after startGlyph (but not including startGlpyh) by delta x in line
- (void)moveGlyphsAfter:(GGlyph*)startGlyph byDeltaX:(CGFloat)deltaX inLine:(GLine*)line {
    NSMutableArray *glyphs = [[self.page textParser] glyphs];
    NSArray *lineGlyphs =  [line glyphs];
    int i;
    for (i = 0; i < [lineGlyphs count]; i++) {
        GGlyph *tmp = [lineGlyphs objectAtIndex:i];
        if (tmp.indexOfBlock > startGlyph.indexOfBlock) {
            NSLog(@"index: %d %@", i, [tmp content]);
            GGlyph *laterGlyph = [lineGlyphs objectAtIndex:i];
            
            int indexOfPage = (int)[glyphs indexOfObject:tmp];
            CGAffineTransform textMatrix = laterGlyph.textMatrix;
            textMatrix.tx += deltaX;
            laterGlyph = [glyphs objectAtIndex:indexOfPage];
            [laterGlyph setTextMatrix:textMatrix];
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
@end
