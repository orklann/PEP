//
//  GTJText.h
//  PEP
//
//  Created by Aaron Elkins on 3/1/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GGlyph;

@interface GTJText : NSObject {
    NSMutableArray *glyphs;
    NSRect frame;
    BOOL cached;
}

+ (id)create;
- (void)addGlyph:(GGlyph*)g;
- (NSMutableArray *)glyphs;
- (void)setGlyphs:(NSMutableArray*)array;
- (NSRect)frame;
@end

NS_ASSUME_NONNULL_END
