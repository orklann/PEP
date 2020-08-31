//
//  GParser.h
//  PEP
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLexer.h"
#import "GObjects.h"

NS_ASSUME_NONNULL_BEGIN

@interface GParser : NSObject {
    GLexer *lexer;
    NSMutableArray *objects;
}

+ (id)parser;
- (GLexer*)lexer;
- (void)setLexer:(GLexer *)l;
- (void)setStream:(NSData*)s;
- (NSMutableArray*)objects;
- (NSMutableArray*)parseWithTokens:(NSMutableArray*)tokens;
- (id)parseNextObject;
- (void)parse; // parse tokens from lexer into GObjects array
@end

NS_ASSUME_NONNULL_END
