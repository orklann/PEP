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
- (void)setType:(int)t {
    type = t;
}

- (int)type {
    return type;
}

- (void)setContent:(NSData *)d {
    content = d;
}

- (NSData*)content {
    return content;
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

- (unsigned char)currentChar {
    unsigned char *bytes = (unsigned char*)[stream bytes];
    return *(bytes + pos);
}

- (GToken *)nextToken {
    unsigned char current = [self currentChar];
    GToken * token = [GToken token];
    unsigned int start = pos;
    switch (current) {
        case 'f':
            if([self nextChar] == 'a' && [self nextChar] == 'l' && [self nextChar] == 's'
               && [self nextChar] == 'e' && isWhiteSpace([self nextChar])){
                [token setType:kBooleanToken];
                unsigned char* bytes = (unsigned char*)[stream bytes];
                NSData *d = [NSData dataWithBytes:bytes + start length:5];
                [token setContent:d];
            }
            break;
        case 't':
            if ([self nextChar] == 'r' && [self nextChar] == 'u' && [self nextChar] == 'e'
                && isWhiteSpace([self nextChar])) {
                [token setType:kBooleanToken];
                unsigned char* bytes = (unsigned char*)[stream bytes];
                NSData *d = [NSData dataWithBytes:bytes + start length:4];
                [token setContent:d];
            }
        default:
            break;
    }
    return token;
}
@end
