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
}

@property (readwrite) unsigned int textBlockIndex;
@property (readwrite) BOOL drawInsertionPoint;
@property (readwrite) GPage *page;

+ (id)textEditorWithPage:(GPage *)p textBlock:(GTextBlock *)tb;
- (GTextEditor*)initWithPage:(GPage *)p textBlock:(GTextBlock*)tb;
- (void)draw:(CGContextRef)context;
- (NSRect)getInsertionPoint;
- (void)keyDown:(NSEvent*)event;
- (void)mouseDown:(NSEvent*)event;
- (NSRect)frame;

// Insert character in insertion point
- (void)insertChar:(NSString *)ch font:(NSFont*)font;
- (GGlyph*)getCurrentGlyph;
@end

NS_ASSUME_NONNULL_END
