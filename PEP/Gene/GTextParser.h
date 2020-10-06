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
}
+ (id)create;
- (NSMutableArray*)glyphs;
- (void)makeReadOrderGlyphs;
@end

NS_ASSUME_NONNULL_END
