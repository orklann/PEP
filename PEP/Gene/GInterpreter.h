//
//  GInterpreter.h
//  PEP
//
//  Created by Aaron Elkins on 9/21/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "GParser.h"
#import "GGlyph.h"

@class GPage;
NS_ASSUME_NONNULL_BEGIN

BOOL isCommand(NSString *cmd, NSString *cmd2);

@interface GInterpreter : NSObject {
    GParser *parser;
    NSMutableData *input;
    GPage *page;
}

/*
 * Current path for graphics path constructions,
 * current path is not in graphics states.
 * See "8.5.2 Path construction operators" in PDF specs
 */
@property (readwrite) CGMutablePathRef currentPath;

+ (id)create;
- (void)setPage:(GPage*)p;
- (void)setParser:(GParser*)p;
- (void)setInput:(NSData *)d;
- (NSMutableArray*)commands;
- (void)parseCommands;
- (void)eval:(CGContextRef)context;

- (CGGlyph)getCGGlyphForGGlyph:(GGlyph*)glyph;
@end

NS_ASSUME_NONNULL_END
