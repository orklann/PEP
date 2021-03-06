//
//  GTextBlock.h
//  PEP
//
//  Created by Aaron Elkins on 10/9/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGlyph;
@class GLine;
NS_ASSUME_NONNULL_BEGIN

@interface GTextBlock : NSObject {
    NSMutableArray *lines;
    NSRect frame;
    BOOL cached;
}
+ (id)create;
- (void)setCached:(BOOL)c;
- (void)setLines:(NSMutableArray*)ls;
- (void)addLine:(GLine*)l;
- (NSMutableArray*)lines;
- (NSArray*)words;
- (NSMutableArray*)glyphs;
- (void)removeGlyph:(GGlyph*)gl;
- (NSRect)frame;
- (NSString*)textBlockString;
- (NSString*)textBlockStringWithLineFeed;
- (void)makeIndexInfoForGlyphs;
- (void)setLineIndexForGlyphs;
- (int)getLineIndex:(int)index;
- (int)getGlyphIndexInLine:(int)index;
- (GLine*)getLineByGlyph:(GGlyph*)g;
- (GTextBlock*)textBlockByAppendingGlyph:(GGlyph*)glyph;
- (GTextBlock*)textBlockByRemovingGlyph:(GGlyph*)glyph;
@end

NS_ASSUME_NONNULL_END
