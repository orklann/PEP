//
//  GTextEditor.h
//  PEP
//
//  Created by Aaron Elkins on 10/14/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@class GGlyph;
@class GTextBlock;
@class GPage;
NS_ASSUME_NONNULL_BEGIN

@interface GTextEditor : NSObject {
    int insertionPointIndex;
    GTextBlock *textBlock;
    NSTimer *blinkTimer;
    NSMutableArray *glyphs;
    NSRect firstGlyphFrame;
}

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
- (NSRect)enlargedFrame;

// Insert character in insertion point
- (void)insertChar:(NSString *)ch font:(NSFont*)font;
- (void)insertChar:(NSString *)ch;

// Insert string in insertion point
// NOTE: Not use yet, but it's useful later
- (void)insertString:(NSString*)string font:(NSFont*)font;
- (void)insertString:(NSString*)string;
- (GGlyph*)getCurrentGlyph;

// Delete current character in insertion point
- (void)deleteCharacter;
- (void)deleteCharacterInInsertionPoint;
@end

NS_ASSUME_NONNULL_END
