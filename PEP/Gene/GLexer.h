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
BOOL isWhiteSpace(unsigned char ch);

enum {
    kBooleanToken
};

@interface GToken : NSObject {
    int type;
    NSData *content;
}
+ (id)token;
- (void)setType:(int)t;
- (int)type;
- (void)setContent:(NSData *)d;
- (NSData*)content;
@end


@interface GLexer : NSObject
{
    NSData *stream;
    unsigned int pos;
}
+ (id)lexer;
- (unsigned int)pos;
- (void)setStream:(NSData*)s;
- (NSData*)stream;
- (unsigned char)nextChar;
- (unsigned char)currentChar;
- (GToken *)nextToken;
@end

NS_ASSUME_NONNULL_END
