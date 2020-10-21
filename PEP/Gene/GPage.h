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
    NSData *pageContent;
    GDocument *doc;
    GDictionaryObject *resources;
    GTextState *textState;
    GGraphicsState *graphicsState;
    NSMutableArray *glyphs;
    GTextParser *textParser;
    NSPoint origin;
    GTextEditor *textEditor;
    NSMutableArray *commands;
}

@property (readwrite) NSMutableDictionary *glyphsForFontDict;
@property (readwrite) BOOL needUpdate;
@property (readwrite) NSMutableArray *dataToUpdate;

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
- (NSFont*)getCurrentFont;
- (GGraphicsState*)graphicsState;
- (GTextState*)textState;
- (GTextParser*)textParser;
- (void)keyDown:(NSEvent*)event;
- (void)mouseDown:(NSEvent*)event;
- (NSRect)rectFromPageToView:(NSRect)rect;
- (void)buildPageContent;
- (void)translateToPageOrigin:(CGContextRef)context;
- (void)redraw;
- (void)initCommands;
- (NSMutableArray *)commands;
- (void)addGlyph:(NSString*)glyphChar font:(NSString*)keyFontName;

#pragma mark Adding stuff as GBinaryData to page
- (void)addFont:(NSFont*)font withPDFFontName:(NSString*)fontKey;

@end

NS_ASSUME_NONNULL_END
