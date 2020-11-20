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
@class GWrappedLine;
NS_ASSUME_NONNULL_BEGIN

@interface GTextEditor : NSObject {
    int insertionPointIndex;
    GTextBlock *textBlock;
    NSTimer *blinkTimer;
    NSMutableArray *glyphs;
    NSMutableArray *cachedGlyphs;
    NSRect firstGlyphFrame;
    GGlyph *lastDeletedGlyph;
    CGFloat editorWidth;
    CGFloat editorHeight;
    CGAffineTransform wordWrapCTM;
    CGAffineTransform wordWrapTextMatrix;
    CGAffineTransform ctm;
    CGAffineTransform textMatrix;
    CGFloat widthLeft;
    GGlyph *lastWrapGlyph;
    BOOL everWrapWord;
    NSMutableArray *wordWrappedLines;
    GWrappedLine *currentWordWrapLine;
}

@property (readwrite) id delegate;
@property (readwrite) BOOL commandsUpdated;
@property (readwrite) NSString *pdfFontName;
@property (readwrite) CGFloat fontSize;
@property (readwrite) BOOL firstUsed;
@property (readwrite) NSMutableArray *editingGlyphs;
@property (readwrite) unsigned int textBlockIndex;
@property (readwrite) BOOL drawInsertionPoint;
@property (readwrite) GPage *page;
@property (readwrite) BOOL isEditing;

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
- (void)insertChar:(NSString *)ch font:(NSFont*)font;
- (void)insertChar:(NSString *)ch;

- (GGlyph*)getCurrentGlyph;
- (GGlyph*)getPrevGlyph;

// Delete current character in insertion point
- (void)deleteCharacter;
- (void)deleteCharacterInInsertionPoint;
@end

NS_ASSUME_NONNULL_END
