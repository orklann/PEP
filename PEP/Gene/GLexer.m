//
//  GLexer.m
//  PEP
//
//  Created by Aaron Elkins on 8/22/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GLexer.h"

BOOL isWhiteSpace(unsigned char ch) {
    switch (ch) {
        case 0x00:
            return YES;
        case 0x09:
            return YES;
        case 0x0A:
            return YES;
        case 0x0C:
            return YES;
        case 0x0D:
            return YES;
        case 0x20:
            return YES;
        default:
            break;
    }
    return NO;
}

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

- (unsigned int)pos {
    return pos;
}

- (void)setStream:(NSData*)s {
    stream = s;
    pos = 0;
}

- (NSData*)stream {
    return stream;
}

- (unsigned char)nextChar {
    unsigned char *bytes = (unsigned char*)[stream bytes];
    unsigned int len = (unsigned int)[stream length];
    if (pos + 1 <= len - 1){
        pos += 1;
    }
    return *(bytes + pos);
}
@end
