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
}

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
- (NSFont*)getCurrentFont;
- (GGraphicsState*)graphicsState;
- (GTextState*)textState;
- (GTextParser*)textParser;
- (void)keyDown:(NSEvent*)event;
- (void)mouseDown:(NSEvent*)event;
- (NSRect)rectFromPageToView:(NSRect)rect;
@end

NS_ASSUME_NONNULL_END
