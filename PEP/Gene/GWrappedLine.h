//
//  GWrappedLine.h
//  PEP
//
//  Created by Aaron Elkins on 10/31/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class GGlyph;
@interface GWrappedLine : NSObject {
    NSMutableArray *glyphs;
    NSRect frame;
}
+ (id)create;
- (NSArray*)glyphs;
- (void)setGlyphs:(NSMutableArray*)gs;
- (void)addGlyph:(GGlyph*)g;
- (NSRect)frame;
- (NSString*)lineString;
- (int)indexforGlyph:(GGlyph*)g;
- (GGlyph*)getGlyphByIndex:(int)index;
@end

NS_ASSUME_NONNULL_END
