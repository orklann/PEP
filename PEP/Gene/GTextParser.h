//
//  GTextParser.h
//  PEP
//
//  Created by Aaron Elkins on 10/5/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GTextParser : NSObject {
    NSMutableArray *glyphs;
    NSMutableArray *words;
}
+ (id)create;
- (NSMutableArray*)glyphs;
- (NSMutableArray*)words;
- (void)makeReadOrderGlyphs;
- (NSMutableArray*)makeWords;
@end

NS_ASSUME_NONNULL_END
