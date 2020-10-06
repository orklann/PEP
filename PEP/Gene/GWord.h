//
//  GWord.h
//  PEP
//
//  Created by Aaron Elkins on 10/6/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGlyph;
NS_ASSUME_NONNULL_BEGIN

@interface GWord : NSObject {
    NSMutableArray *glyphs;
    NSRect frame;
}

+ (id)create;
- (void)setFrame:(NSRect)f;
- (NSRect)frame;
- (NSMutableArray*)glyphs;
- (void)addGlyph:(GGlyph*)g;
@end

NS_ASSUME_NONNULL_END
