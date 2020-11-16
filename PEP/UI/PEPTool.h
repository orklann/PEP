//
//  PEPTool.h
//  PEP
//
//  Created by Aaron Elkins on 11/16/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN
@class PEPToolbarView;

#define kToolHeight 24
#define kToolWidthMargin 8

@interface PEPTool : NSObject {
    NSImage *image;
    NSImage *selectedImage;
    NSString *text;
    PEPToolbarView *toolbarView;
    BOOL selected;
}

+ (id)create;
- (void)setSelected:(BOOL)s;
- (void)setToolbarView:(PEPToolbarView*)tb;
- (void)setImage:(NSImage*)img;
- (void)setSelectedImage:(NSImage*)img;
- (void)setText:(NSString*)s;
- (CGFloat)width;
- (void)draw:(CGContextRef)context;
@end

NS_ASSUME_NONNULL_END
