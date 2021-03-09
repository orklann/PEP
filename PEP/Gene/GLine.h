//
//  GLine.h
//  PEP
//
//  Created by Aaron Elkins on 10/8/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GWord;

NS_ASSUME_NONNULL_BEGIN

@interface GLine : NSObject {
    NSMutableArray *words;
    NSRect frame;
}

@property (readwrite) CGAffineTransform startTextMatrix;

+ (id)create;
- (void)setWords:(NSMutableArray*)ws;
- (void)addWord:(GWord*)w;
- (NSMutableArray*)words;
- (NSArray*)glyphs;
- (NSRect)frame;
- (NSString*)lineString;
@end

NS_ASSUME_NONNULL_END
