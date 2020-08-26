//
//  GLexer.h
//  PEP
//
//  Created by Aaron Elkins on 8/22/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Return by isEndLineMarker()
#define kNOT_END_LINE_MARKER -1
#define kTWO_END_LINE_MARKERS 2
#define kONE_END_LINE_MARKER 1


#define kCARRIAGE_RETURN 0x0D
#define kLINE_FEED 0x0A

// Test for white space char
BOOL isWhiteSpace(unsigned char ch);
int isEndLineMarker(unsigned char ch1, unsigned char ch2);

enum {
    kBooleanToken,
    kNumberToken,
    kLiteralStringsToken,
    kHexadecimalStringsToken,
    kNameObjectToken,
    kArrayObjectToken,
    kDictionaryObjectToken,
    kStreamContentToken
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


@interface GLexer : NSObject {
    NSData *stream;
    unsigned int pos;
}

+ (id)lexer;
- (unsigned int)pos;
- (void)setStream:(NSData*)s;
- (NSData*)stream;
- (unsigned char)nextChar;
- (unsigned char)currentChar;
- (unsigned char)peekNextChar;
- (GToken *)nextToken;
@end

NS_ASSUME_NONNULL_END
