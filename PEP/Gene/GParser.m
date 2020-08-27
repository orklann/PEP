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
    GToken *t = [lexer nextToken];
    while([t type] != kEndToken) {
        int type = [t type];
        switch (type) {
            case kBooleanToken:
            {
                GBooleanObject *o = [GBooleanObject create];
                [o setType:kBooleanObject];
                if ([[t content] isEqualToData:[NSData dataWithBytes:"false" length:5]]) {
                    [o setValue:NO];
                } else if ([[t content] isEqualToData:[NSData dataWithBytes:"true" length:4]]) {
                    [o setValue:YES];
                }
                [objects addObject:o];
                break;
            }
                
            default:
                break;
        }
        t = [lexer nextToken];
    }
}
@end
