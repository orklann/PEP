//
//  GCompiler.h
//  PEP
//
//  Created by Aaron Elkins on 11/10/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GPage;

@interface GCompiler : NSObject {
    GPage *page;
    CGFloat currentWordSpace;
    CGFloat currentCharSpace;
}
+ (id)compilerWithPage:(GPage*)page;
- (void)setPage:(GPage*)p;
- (NSString*)compile;

- (NSArray*)buildGlyphsGroupArray;
- (NSArray*)buildGlyphsGroupArray:(NSArray*)originalArray;
@end

NS_ASSUME_NONNULL_END
