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
    pos = 0;
}

- (NSData*)stream {
    return stream;
}

- (char)nextChar {
    unsigned char *bytes = (unsigned char*)[stream bytes];
    pos += 1;
    return *(bytes + pos);
}
@end
