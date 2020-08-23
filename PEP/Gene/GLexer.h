//
//  GLexer.h
//  PEP
//
//  Created by Aaron Elkins on 8/22/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Test for white space char
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

@interface GToken : NSObject {
    int type;
    NSData *content;
}
+ (id)token;
@end


@interface GLexer : NSObject
{
    NSData *stream;
    unsigned int pos;
}
+ (id)lexer;
- (void)setStream:(NSData*)s;
- (NSData*)stream;
- (char)nextChar;
@end

NS_ASSUME_NONNULL_END
