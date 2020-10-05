//
//  GPage.h
//  PEP
//
//  Created by Aaron Elkins on 9/17/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GObjects.h"
#import "GParser.h"
#import "GTextState.h"
#import "GGraphicsState.h"
#import "GTextParser.h"

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
    GTextParser *textPraser;
}

+ (id)create;
- (void)setPageDictionary:(GDictionaryObject*)d;
- (GDictionaryObject*)pageDictionary;
- (void)setParser:(GParser*)p;
- (GParser*)parser;
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
@end

NS_ASSUME_NONNULL_END
