//
//  GParser.m
//  PEP
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GParser.h"
#import "GObjects.h"

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

- (void)setStream:(NSData*)s {
    [lexer setStream:s];
    objects = [NSMutableArray array];
}

- (NSMutableArray*)objects {
    return objects;
}

- (void)parse {
    NSMutableArray *tokens = [NSMutableArray array];
    GToken *t = [lexer nextToken];
    while([t type] != kEndToken) {
        [tokens addObject:t];
        t = [lexer nextToken];
    }
    
    NSUInteger i = 0;
    for (i = 0; i < [tokens count]; i++) {
        GToken *token = [tokens objectAtIndex:i];
        int type = [token type];
        switch (type) {
            case kBooleanToken:
            {
                GBooleanObject *o = [GBooleanObject create];
                [o setType:kBooleanObject];
                [o setRawContent:[token content]];
                [o parse];
                [objects addObject:o];
                break;
            }
            
            case kNumberToken:
            {
                GNumberObject *o = [GNumberObject create];
                [o setType:kNumberObject];
                [o setRawContent:[token content]];
                [o parse];
                [objects addObject:o];
                break;
            }
            default:
                break;
        }
    }
}
@end
