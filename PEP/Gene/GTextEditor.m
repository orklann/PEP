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

- (void)saveEditingGlyphs {
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
    return [textBlock frame];
}

- (NSRect)enlargedFrame {
    return NSInsetRect([self frame], -3, -3);
}

- (NSRect)getInsertionPoint {
    NSArray *glyphs = [textBlock glyphs];
    NSRect ret;
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
    } else if (keyCode == kRightArrow) {
        if (insertionPointIndex + 1 <= [glyphs count]) {
            insertionPointIndex++;
        }
    } else if (keyCode == kUpArrow) {
        int currentLineIndex = [textBlock getLineOfGlyphIndex:insertionPointIndex];
        if (currentLineIndex != -1) { // No errors
            if (currentLineIndex - 1 >= 0) {
                int previousLineIndex = currentLineIndex - 1;
                GLine *prevLine = [[textBlock lines] objectAtIndex:previousLineIndex];
                int glyphIndexInCurrentLine = [textBlock indexOfLineForGlyphIndex:insertionPointIndex];
                if (glyphIndexInCurrentLine > (int)[[prevLine glyphs] count] - 1) {
                    glyphIndexInCurrentLine = (int)[[prevLine glyphs] count] - 1;
                }
                int glyphIndexInPrevLine = glyphIndexInCurrentLine;
                GGlyph *currentGlyph = [[prevLine glyphs] objectAtIndex:glyphIndexInPrevLine];
                insertionPointIndex = currentGlyph.indexOfBlock;
            }
        } else if (insertionPointIndex == [glyphs count]) { // Edge case: insertion point is at the end of text
            int currentLineIndex = [textBlock getLineOfGlyphIndex:insertionPointIndex - 1];
            if (currentLineIndex != -1) { // No errors
                if (currentLineIndex - 1 >= 0) {
                    int previousLineIndex = currentLineIndex - 1;
                    GLine *prevLine = [[textBlock lines] objectAtIndex:previousLineIndex];
                    int glyphIndexInCurrentLine = [textBlock indexOfLineForGlyphIndex:insertionPointIndex-1];
                    if (glyphIndexInCurrentLine > (int)[[prevLine glyphs] count] - 1) {
                        glyphIndexInCurrentLine = (int)[[prevLine glyphs] count] - 1;
                    }
                    int glyphIndexInPrevLine = glyphIndexInCurrentLine;
                    GGlyph *currentGlyph = [[prevLine glyphs] objectAtIndex:glyphIndexInPrevLine];
                    insertionPointIndex = currentGlyph.indexOfBlock + 1;
                }
            }
        }
    } else if (keyCode == kDownArrow) {
        int currentLineIndex = [textBlock getLineOfGlyphIndex:insertionPointIndex];
        if (currentLineIndex != -1) { // No errors
            if (currentLineIndex + 1 <= [[textBlock lines] count] - 1) {
                int nextLineIndex = currentLineIndex + 1;
                GLine *nextLine = [[textBlock lines] objectAtIndex:nextLineIndex];
                int glyphIndexInCurrentLine = [textBlock indexOfLineForGlyphIndex:insertionPointIndex];
                
                
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
        NSString *ch =[event characters];
        unichar key = [ch characterAtIndex:0];
        if(key == NSDeleteCharacter) {
            // TODO: Handle delete key
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

- (void)insertChar:(NSString *)ch font:(NSFont*)font {
    GGlyph *currentGlyph;
    if (insertionPointIndex > [[textBlock glyphs] count] - 1) {
        currentGlyph = [[textBlock glyphs] lastObject];
    } else {
        currentGlyph = [[textBlock glyphs] objectAtIndex:insertionPointIndex];
    }
    
    int currentIndexInLine = [textBlock indexOfLineForGlyphIndex:insertionPointIndex];
    int lineIndex = [textBlock getLineOfGlyphIndex:insertionPointIndex];
    GLine *currentLine = [[textBlock lines] objectAtIndex:lineIndex];
    NSArray *lineGlyphs = [currentLine glyphs];
    NSMutableArray *glyphs = [self.page.textParser glyphs];
    int prevIndex = currentIndexInLine - 1;
    
    // Insertion point is at the beginning of line
    if (prevIndex < 0) {
        prevIndex = 0;
    }
    
    if (insertionPointIndex > [[textBlock glyphs] count] - 1) {
        // Advance by 1 glyph, because substract by 1 from currentIndexInLine,
        // we need to go foward 1 glyph in this case (insertion point is at the end of text block)
        prevIndex += 1;
    }
    
    NSLog(@"line: %d prev index: %d", lineIndex, prevIndex);
    
    if (prevIndex >= 0) {
        GGlyph *prevGlyph = [[currentLine glyphs] objectAtIndex:prevIndex];
        CGAffineTransform ctm = prevGlyph.ctm;
        CGAffineTransform tm = prevGlyph.textMatrix;
        NSString *fontName = prevGlyph.fontName;
        CGFloat fontSize = prevGlyph.fontSize;
        CGFloat glyphWidth = prevGlyph.width;
        if (currentIndexInLine > 0) {
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
        
        if ([ch isEqualToString:@"\t"]) {
            // NOTE: (TAB) This clause will never reach because when a \t is entered,
            // We convert it into a '   '.
            // But I will leave this code her for alternative method to
            // get glyph width
            CGRect rect;
            CGFontRef cgFont = CTFontCopyGraphicsFont((CTFontRef)font, nil);
            CGGlyph g = CGFontGetGlyphWithGlyphName(cgFont, CFSTR("\t"));
            CGFontGetGlyphBBoxes(cgFont, &g, 1, &rect);

            hAdvance = rect.size.width / CGFontGetUnitsPerEm(cgFont) * fontSize;
            NSLog(@"(TAB) width: %f", hAdvance);
        } else {
            hAdvance = getGlyphAdvanceForFont(ch, font);
        }

        s = NSMakeSize(hAdvance, 0);
        s = CGSizeApplyAffineTransform(s, tm);
        
        int i;
        for (i = 0; i < [lineGlyphs count]; i++) {
            GGlyph *tmp = [lineGlyphs objectAtIndex:i];
            if (tmp.indexOfBlock >= currentGlyph.indexOfBlock) {
                NSLog(@"index: %d %@", i, [tmp content]);
                GGlyph *laterGlyph = [lineGlyphs objectAtIndex:i];
                
                // NOTE: We remove indexOfPage in GGlyph
                // TODO: Maybe we need indexOfPage in GGlyph later.
                // Find the index of original page glyphs, and update the glyph
                int indexOfPage = (int)[[[self.page textParser] glyphs] indexOfObject:tmp];
                CGAffineTransform textMatrix = laterGlyph.textMatrix;
                textMatrix.tx += s.width;
                laterGlyph = [[[self.page textParser] glyphs] objectAtIndex:indexOfPage];
                [laterGlyph setTextMatrix:textMatrix];
            }
        }
        insertionPointIndex++;
    }
}

- (void)insertChar:(NSString *)ch {
    if (self.isEditing) return ;
    self.isEditing = YES;
    // Test insert character into text editor
    // Fixme: use any font here, font is not useful by now
    GGlyph *g = [self getCurrentGlyph];
    NSFont *font = [NSFont fontWithName:@"Gill Sans" size:[g fontSize]];
    [self insertChar:ch font:font];
    [self.page buildPageContent];
    [self.page addFont:font withPDFFontName:[g fontName]];
    [self.page addPageStream];
    [self.page incrementalUpdate];
    [self.page setNeedUpdate:YES];
    self.isEditing = NO;
}

- (void)insertString:(NSString*)string font:(NSFont*)font {
    GGlyph *currentGlyph;
    if (insertionPointIndex > [[textBlock glyphs] count] - 1) {
        currentGlyph = [[textBlock glyphs] lastObject];
    } else {
        currentGlyph = [[textBlock glyphs] objectAtIndex:insertionPointIndex];
    }
    
    int currentIndexInLine = [textBlock indexOfLineForGlyphIndex:insertionPointIndex];
    int lineIndex = [textBlock getLineOfGlyphIndex:insertionPointIndex];
    GLine *currentLine = [[textBlock lines] objectAtIndex:lineIndex];
    NSArray *lineGlyphs = [currentLine glyphs];
    NSMutableArray *glyphs = [self.page.textParser glyphs];
    int prevIndex = currentIndexInLine - 1;
    
    // Insertion point is at the beginning of line
    if (prevIndex < 0) {
        prevIndex = 0;
    }
    
    if (insertionPointIndex > [[textBlock glyphs] count] - 1) {
        // Advance by 1 glyph, because substract by 1 from currentIndexInLine,
        // we need to go foward 1 glyph in this case (insertion point is at the end of text block)
        prevIndex += 1;
    }
    
    NSLog(@"line: %d prev index: %d", lineIndex, prevIndex);
    
    if (prevIndex >= 0) {
        GGlyph *prevGlyph = [[currentLine glyphs] objectAtIndex:prevIndex];
        CGAffineTransform ctm = prevGlyph.ctm;
        CGAffineTransform tm = prevGlyph.textMatrix;
        NSString *fontName = prevGlyph.fontName;
        CGFloat fontSize = prevGlyph.fontSize;
        CGFloat glyphWidth = prevGlyph.width;
        if (currentIndexInLine > 0) {
            tm.tx += glyphWidth;
        }
        
        int len = (int)[string length];
        int i;
        CGAffineTransform incrementalTextMatrix = tm;
        CGFloat width = 0;
        
        for (i = 0; i < len; i++) {
            GGlyph *g = [GGlyph create];
            NSString *ch = [string substringWithRange:NSMakeRange(i, 1)];
            [g setContent:ch];
            [g setCtm:ctm];
            [g setTextMatrix:incrementalTextMatrix];
            [g setFontName:fontName];
            [g setFontSize:fontSize];
            [glyphs addObject:g];
            
            // Update width for later glyphs
            CGFloat hAdvance = getGlyphAdvanceForFont(ch, font);
            NSSize s = NSMakeSize(hAdvance, 0);
            s = CGSizeApplyAffineTransform(s, incrementalTextMatrix);
            width += s.width;
            
            // Update incremantal text matrix for next glyph by adding current
            // glyph width
            incrementalTextMatrix.tx += s.width;
        }
        
 
        
        // We don't need to care about later glyphs, since insertion point is
        // at the end of text block
        if (insertionPointIndex > [[textBlock glyphs] count] - 1) {
            insertionPointIndex += len;
            return ;
        }
        
        for (i = 0; i < [lineGlyphs count]; i++) {
            GGlyph *tmp = [lineGlyphs objectAtIndex:i];
            if (tmp.indexOfBlock >= currentGlyph.indexOfBlock) {
                NSLog(@"index: %d %@", i, [tmp content]);
                GGlyph *laterGlyph = [lineGlyphs objectAtIndex:i];
                int indexOfPage = (int)[[[self.page textParser] glyphs] indexOfObject:tmp];
                CGAffineTransform textMatrix = laterGlyph.textMatrix;
                textMatrix.tx += width;
                laterGlyph = [[[self.page textParser] glyphs] objectAtIndex:indexOfPage];
                [laterGlyph setTextMatrix:textMatrix];
            }
        }
        insertionPointIndex += len;
    }
}

- (void)insertString:(NSString*)string {
    if (self.isEditing) return ;
    self.isEditing = YES;
    // Test insert character into text editor
    // Fixme: use any font here, font is not useful by now
    GGlyph *g = [self getCurrentGlyph];
    NSFont *font = [NSFont fontWithName:@"Gill Sans" size:[g fontSize]];
    [self insertString:string font:font];
    [self.page buildPageContent];
    [self.page addFont:font withPDFFontName:[g fontName]];
    [self.page addPageStream];
    [self.page incrementalUpdate];
    [self.page setNeedUpdate:YES];
    self.isEditing = NO;
}

- (GGlyph*)getCurrentGlyph {
    GGlyph *currentGlyph;
    if (insertionPointIndex > [[textBlock glyphs] count] - 1) {
        currentGlyph = [[textBlock glyphs] lastObject];
    } else {
        currentGlyph = [[textBlock glyphs] objectAtIndex:insertionPointIndex];
    }
    return currentGlyph;
}
@end
