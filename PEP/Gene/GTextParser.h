//
//  GTextParser.h
//  PEP
//
//  Created by Aaron Elkins on 10/5/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class GGlyph;

@interface GTextParser : NSObject {
    NSMutableArray *glyphs;
    NSMutableArray *words;
    NSMutableArray *lines;
    NSMutableArray *textBlocks;
    unsigned int glyphPos;
}
+ (id)create;
- (NSMutableArray*)glyphs;
- (GGlyph*)nextGlyph;
- (GGlyph*)currentGlyph;
- (NSMutableArray*)words;
- (void)makeReadOrderGlyphs;
- (NSMutableArray*)makeWords;
- (NSMutableArray*)makeLines;
- (NSMutableArray*)makeTextBlocks;
@end

NS_ASSUME_NONNULL_END
