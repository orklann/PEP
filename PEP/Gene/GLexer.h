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

// Test for stream content end line markers
int isEndLineMarker(unsigned char ch1, unsigned char ch2);

typedef enum {
    kUnknownToken,
    kBooleanToken,
    kNumberToken,
    kLiteralStringsToken,
    kHexadecimalStringsToken,
    kNameObjectToken,
    kArrayObjectToken,
    kDictionaryObjectToken,
    kStreamContentToken,
    kNullObjectToken,
    kIndirectObjectContentToken,
    kRefToken,
    kCommandToken,
    kEndToken,
} TokenType;

@interface GToken : NSObject {
    TokenType type;
    NSData *content;
    NSData *originalContent;
}

@property (readwrite) unsigned int startPos;

+ (id)token;
- (void)setType:(TokenType)t;
- (TokenType)type;
- (void)setContent:(NSData *)d;
- (NSData*)content;
- (void)setOriginalContent:(NSData*)d;
- (NSData*)originalContent;
@end


@interface GLexer : NSObject {
    NSMutableData *stream;
    unsigned int pos;
}

+ (id)lexer;
- (unsigned int)pos;
- (void)setPos:(unsigned int)p;
- (void)setStream:(NSData*)s;
- (NSMutableData*)stream;
- (unsigned char)nextChar;
- (unsigned char)currentChar;
- (unsigned char)peekNextChar;
- (GToken *)nextToken;

// This method return next line only for use in parsing xref entries
- (NSString*)nextLine;
@end

NS_ASSUME_NONNULL_END
