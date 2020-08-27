//
//  GParser.h
//  PEP
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLexer.h"

NS_ASSUME_NONNULL_BEGIN

@interface GParser : NSObject {
    GLexer *lexer;
}

+ (id)parser;
- (GLexer*)lexer;
- (void)setLexer:(GLexer *)l;
@end

NS_ASSUME_NONNULL_END
