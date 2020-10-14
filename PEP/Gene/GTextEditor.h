//
//  GTextEditor.h
//  PEP
//
//  Created by Aaron Elkins on 10/14/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@class GTextBlock;
@class GPage;
NS_ASSUME_NONNULL_BEGIN

@interface GTextEditor : NSObject {
    int insertionPointIndex;
    GTextBlock *textBlock;
    NSTimer *blinkTimer;
}

@property (readwrite) BOOL drawInsertionPoint;
@property (readwrite) GPage *page;

+ (id)textEditorWithPage:(GPage *)p textBlock:(GTextBlock *)tb;
- (GTextEditor*)initWithPage:(GPage *)p textBlock:(GTextBlock*)tb;
- (void)draw:(CGContextRef)context;
- (NSRect)getInsertionPoint;
- (void)keyDown:(NSEvent*)event;
- (void)mouseDown:(NSEvent*)event;
@end

NS_ASSUME_NONNULL_END
