//
//  GTextEditor.h
//  PEP
//
//  Created by Aaron Elkins on 10/14/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "GTextEditorDelegate.h"

@class GGlyph;
@class GTextBlock;
@class GPage;
@class GLine;
@class GFontEncoding;
NS_ASSUME_NONNULL_BEGIN

@interface GTextEditor : NSObject {
    int insertionPointIndex;
    GTextBlock *textBlock;
    NSTimer *blinkTimer;
    NSRect firstGlyphFrame;
    GGlyph *lastDeletedGlyph;
    CGFloat editorWidth;
    CGFloat editorHeight;
    CGAffineTransform ctm;
    CGAffineTransform textMatrix;
    CGFloat widthLeft;
}

@property (readwrite) GPage *editorInPage;
@property (readwrite) id delegate;
@property (readwrite) BOOL commandsUpdated;
@property (readwrite) NSString *pdfFontName;
@property (readwrite) CGFloat fontSize;
@property (readwrite) NSMutableArray *editingGlyphs;
@property (readwrite) unsigned int textBlockIndex;
@property (readwrite) BOOL drawInsertionPoint;
@property (readwrite) GPage *page;
@property (readwrite) BOOL isEditing;
@property (readwrite) char * _Nonnull * _Nonnull encoding;
@property (readwrite) GFontEncoding* fontEncoding;

+ (id)textEditorWithPage:(GPage *)p textBlock:(GTextBlock *)tb;
- (GTextEditor*)initWithPage:(GPage *)p textBlock:(GTextBlock*)tb;
- (void)draw:(CGContextRef)context;
- (NSRect)getInsertionPoint;
- (void)keyDown:(NSEvent*)event;
- (void)mouseDown:(NSEvent*)event;
- (NSRect)frame;
- (CGFloat)getEditorWidth;
- (NSRect)enlargedFrame;

// Insert character in insertion point
- (void)insertChar:(NSString *)ch
              font:(NSFont*)font
           fontTag:(NSString*)fontName
    fontIsExternal:(BOOL)fontIsExternal;

- (void)insertChar:(NSString *)ch;

- (GGlyph*)getCurrentGlyph;
- (GGlyph*)getPrevGlyph;

// Delete current character in insertion point
- (void)deleteCharacter;
- (void)deleteCharacterInInsertionPoint;

// Get text states
- (CGFloat)getFontSizeForEditor;
- (NSString*)getPDFFontNameForEditor;

// Stop blink timer
- (void)stopBlinkTimer;

- (BOOL)glyph:(NSString*)ch foundInFont:(NSFont*)font;
@end

NS_ASSUME_NONNULL_END
