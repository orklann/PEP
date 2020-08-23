//
//  GLexer.m
//  PEP
//
//  Created by Aaron Elkins on 8/22/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GLexer.h"

@implementation GToken
+ (id)token {
    GToken *t = [[GToken alloc] init];
    return t;
}
@end

@implementation GLexer
+ (id)lexer {
    GLexer *l = [[GLexer alloc] init];
    return l;
}

- (void)setStream:(NSData*)s {
    stream = s;
}

- (NSData*)stream {
    return stream;
}
@end
