//
//  GPage.h
//  PEP
//
//  Created by Aaron Elkins on 9/17/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "GObjects.h"
#import "GParser.h"
#import "GTextState.h"
#import "GGraphicsState.h"
#import "GTextParser.h"
#import "GTextEditor.h"

@class GDocument;
@class GFont;

NS_ASSUME_NONNULL_BEGIN

#define kPageMargin 20

@interface GPage : NSObject {
    GDictionaryObject *pageDictionary;
    GParser *parser;
    NSMutableData *pageContent;
    GDocument *doc;
    GDictionaryObject *resources;
    GTextState *textState;
    GGraphicsState *graphicsState;
    NSMutableArray *graphicsStateStack;
    NSMutableArray *glyphs;
    GTextParser *textParser;
    NSPoint origin;
    NSMutableArray *commands;
    NSRect highlightBlockFrame;
}

@property (readwrite) GRefObject *pageRef;
@property (readwrite) CGFloat pageYOffsetInDoc;
@property (readwrite) BOOL isRendering;
@property (readwrite) unsigned int lastStreamOffset;
@property (readwrite) NSMutableDictionary *cachedFonts;
@property (readwrite) NSMutableDictionary *addedFonts;
@property (readwrite) NSMutableDictionary *glyphsForFontDict;
@property (readwrite) BOOL needUpdate;
@property (readwrite) BOOL dirty;

+ (id)create;
- (void)setPageDictionary:(GDictionaryObject*)d;
- (GDictionaryObject*)pageDictionary;
- (NSPoint)origin;
- (void)setParser:(GParser*)p;
- (GParser*)parser;
- (GDocument*)doc;
- (void)setDocument:(GDocument*)d;
- (void)parsePageContent;
- (void)parseResources;
- (GDictionaryObject*)resources;
- (void)render:(CGContextRef)context;
- (NSRect)calculatePageMediaBox;
- (GFont*)getFontByName:(NSString*)name;
- (NSFont*)getFontByName:(NSString*)name size:(CGFloat)size;
- (NSFont*)getCurrentFont:(NSString*)s;
- (NSFont*)getCachedFontForKey:(NSString*)key;
- (NSFont*)getCachedFontByFontTag:(NSString*)fontTag;
- (NSString*)getFontNameByFontTag:(NSString*)fontTag;
- (GGraphicsState*)graphicsState;
- (GTextState*)textState;
- (GTextParser*)textParser;
- (void)keyDown:(NSEvent*)event;
- (void)mouseMoved:(NSEvent*)event;
- (void)mouseDown:(NSEvent*)event;
- (NSRect)rectFromPageToView:(NSRect)rect;
- (NSPoint)pointFromPageToView:(NSPoint)p;
- (void)buildPageContent;
- (void)translateToPageOrigin:(CGContextRef)context;
- (void)redraw;
- (void)initCommands;
- (NSMutableArray *)commands;
- (void)addGlyph:(NSString*)glyphChar font:(NSString*)keyFontName;

#pragma mark Adding stuff as GBinaryData to page
// Add new font into dataToUpdate, later use it to update GDocument stream
// Return font dictionary ref for later use in page resource's font array
- (NSString*)addFont:(NSFont*)font withPDFFontName:(NSString*)fontKey;

// Add all new added fonts into dataToUpdate for updating, which calls
// - (NSString*)addFont:(NSFont*)font withPDFFontName:(NSString*)fontKey
// And also create new page resource dictionary.
- (void)addNewAddedFontsForUpdating;

// Add page stream into dataToUpdate, later use it to update GDocument stream
- (void)addPageStream;

// Incremental update
- (void)incrementalUpdate;

// Build cached fonts for this page
- (void)buildCachedFonts;

// Add new font with PDF font key
- (void)addNewFont:(NSFont*)font withPDFFontTag:(NSString*)fontTag;

// Graphics state stacks operation
- (void)saveGraphicsState;
- (void)restoreGraphicsState;

// Generate new PDF font tag
- (NSString*)generateNewPDFFontTag;

// Get CTLineRef for glyph in page
- (CTLineRef)getLineFromGlyph:(GGlyph*)glyph;

// Build font encodings in page
- (void)buildFontEncodings;

// Debug
- (void)logPageContent;
@end

NS_ASSUME_NONNULL_END
