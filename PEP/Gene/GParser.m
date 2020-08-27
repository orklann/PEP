//
//  GParser.m
//  PEP
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GParser.h"

@implementation GParser

+ (id)parser {
    GParser *p = [[GParser alloc] init];
    GLexer *l = [GLexer lexer];
    [p setLexer:l];
    return p;
}

- (void)setLexer:(GLexer*)l {
    lexer = l;
}

- (GLexer*)lexer {
    return lexer;
}
@end
