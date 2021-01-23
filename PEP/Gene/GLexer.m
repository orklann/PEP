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
        case 0x09:
        case 0x0A:
        case 0x0C:
        case 0x0D:
        case 0x20:
            return YES;
        default:
            break;
    }
    return NO;
}

BOOL isNumberChar(unsigned char ch) {
    switch (ch) {
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case '+':
        case '-':
        case '.':
            return YES;
        default:
            break;
    }
    return NO;
}

BOOL isDelimiter(unsigned char ch) {
    switch(ch) {
        case '<':
        case '>':
        case '[':
        case ']':
        case '(':
        case ')':
        case '{':
        case '}':
        case '%':
        case '/':
            return YES;
        default:
            break;
    }
    return NO;
}

int isEndLineMarker(unsigned char ch1, unsigned char ch2) {
    if (ch1 == kCARRIAGE_RETURN && ch2 == kLINE_FEED) {
        return kTWO_END_LINE_MARKERS ;
    } else if (ch1 == kLINE_FEED) {
        return kONE_END_LINE_MARKER;
    }
    return kNOT_END_LINE_MARKER;
}

@implementation GToken
+ (id)token {
    GToken *t = [[GToken alloc] init];
    [t setType:kUnknownToken];
    return t;
}

- (void)setType:(TokenType)t {
    type = t;
}

- (TokenType)type {
    return type;
}

- (void)setContent:(NSData *)d {
    content = d;
}

- (NSData*)content {
    return content;
}

- (void)setOriginalContent:(NSData*)d {
    originalContent = d;
}

- (NSData*)originalContent {
    return originalContent;
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

- (void)setPos:(unsigned int)p {
    pos = p;
}

- (void)setStream:(NSData*)s {
    stream = [NSMutableData dataWithData:s];
    pos = 0;
}

- (NSMutableData*)stream {
    return stream;
}

- (unsigned char)nextChar {
    unsigned char *bytes = (unsigned char*)[stream bytes];
    unsigned int len = (unsigned int)[stream length];
    if (pos + 1 <= len){
        pos += 1;
    }
    return *(bytes + pos);
}

- (unsigned char)peekNextChar {
    unsigned char *bytes = (unsigned char*)[stream bytes];
    unsigned int len = (unsigned int)[stream length];
    int peekPos = pos;
    if (pos + 1 <= len){
        peekPos = pos + 1;
    }
    return *(bytes + peekPos);
}

- (unsigned char)currentChar {
    unsigned char *bytes = (unsigned char*)[stream bytes];
    return *(bytes + pos);
}

- (NSData *)getNumber {
    unsigned char current = [self currentChar];
    NSMutableData *d = [NSMutableData dataWithCapacity:100];
    [d appendBytes:(unsigned char*)&current length:1];
    
    unsigned char next = [self nextChar];
    while(!isWhiteSpace(next)) {
        if (isDelimiter(next)) break;
        [d appendBytes:(unsigned char*)&next length:1];
        next = [self nextChar];
    }
    return (NSData*)d;
}

- (NSData*)getLiteralStrings {
    NSMutableData *d = [NSMutableData dataWithCapacity:100];
    unsigned char next = [self currentChar];
    int unbalanced = 1;
    [d appendBytes:(unsigned char*)&next length:1];
    unsigned char prev = next;
    next = [self nextChar];
    BOOL escappedBackSlash = NO;
    if (next == '(' && prev != '\\') { // Handle (\()
        unbalanced += 1;
    } else if (next == ')' && (prev != '\\' || escappedBackSlash) ) { // Handle (\))
        // Paired, if prev character is not a '\'  - This case: (\))
        // Paired, if prev character is escaped, even it's a '\', - this case: (\\)
        unbalanced -= 1;
    }
    while(unbalanced != 0) {
        if (next == '\\' && prev == '\\') escappedBackSlash = YES;
        if (next == '(' && prev != '\\') { // Handle (\()
            unbalanced += 1;
        } else if (next == ')' && (prev != '\\' || escappedBackSlash)) {
            // Paired, if prev character is not a '\' this case: (\))
            // Paired, if prev character is escaped, even it's a '\', - this case: (\\)
            unbalanced -= 1;
        }
        [d appendBytes:(unsigned char*)&next length:1];
        prev = next;
        next = [self nextChar];
        if (next == '\\') escappedBackSlash = NO;
    }
    d = [NSMutableData dataWithBytes:([d bytes]+1) length:[d length] - 2];
    [d appendBytes:"\0" length:1];
    return d;
}

- (NSData *)getHexadecimalStrings {
    NSMutableData *d = [NSMutableData dataWithCapacity:1024];
    unsigned char next = [self currentChar];
    [d appendBytes:(unsigned char*)&next length:1];
    next = [self nextChar];
    while(next != '>') {
        [d appendBytes:(unsigned char*)&next length:1];
        next = [self nextChar];
    }
    // Append '0' if the length of hexademical strings is not even
    if ([d length] % 2 != 0){
        [d appendBytes:"0" length:1];
    }
    [self nextChar]; // Fix infinite loop
    return (NSData*)d;
}

- (NSData *)getName {
    NSMutableData *d = [NSMutableData dataWithCapacity:100];
    unsigned char next = [self nextChar];
    while(!isWhiteSpace(next)) {
        if (isDelimiter(next)) break;
        if (next == '#') {
            unsigned char ch1 = [self nextChar];
            unsigned char ch2 = [self nextChar];
            unsigned char s[3];
            long hex;
            sprintf((char*)&s, "%c%c", ch1, ch2);
            hex = strtol((char *)s, NULL, 16);
            sprintf((char*)&s, "%c", (int)hex);
            [d appendBytes:(unsigned char*)&s length:1];
        } else {
            [d appendBytes:(unsigned char*)&next length:1];
        }
        next = [self nextChar];
    }
    return (NSData*)d;
}

- (NSData*)getNameOriginal {
    int savedOffset = [self pos];
    NSMutableData *d = [NSMutableData dataWithCapacity:100];
    unsigned char next = [self nextChar];
    while(!isWhiteSpace(next)) {
        [d appendBytes:(unsigned char*)&next length:1];
        next = [self nextChar];
    }
    pos = savedOffset;
    return (NSData*)d;
}

- (NSData *)getArray {
    NSMutableData *d = [NSMutableData dataWithCapacity:100];
    unsigned char next = [self currentChar];
    int unbalanced = 1;
    [d appendBytes:(unsigned char*)&next length:1];
    next = [self nextChar];
    if (next == '[') {
        unbalanced += 1;
    } else if (next == ']') {
        unbalanced -= 1;
        [d appendBytes:(unsigned char*)&next length:1];
        [self nextChar];
    }
    while(unbalanced != 0) {
        if (next == '[') {
            unbalanced += 1;
        } else if (next == ']') {
            unbalanced -= 1;
        }
        [d appendBytes:(unsigned char*)&next length:1];
        next = [self nextChar];
    }
    
    // return array content without [ and ]
    return [NSData dataWithBytes:[d bytes] + 1  length:[d length] - 2];
}

- (NSData *)getDictionary {
    NSMutableData *d = [NSMutableData dataWithCapacity:100];
    int unbalanced = 1;
    [d appendBytes:(unsigned char*)"<<" length:2];
    unsigned char next = [self nextChar];
    while(unbalanced != 0) {
        if (next == '<' && [self peekNextChar] == '<') {
            unbalanced += 1;
            [self nextChar];
            [d appendBytes:(unsigned char*)"<<" length:2];
            next = [self nextChar];
        } else if (next == '>' && [self peekNextChar] == '>') {
            unbalanced -= 1;
            [self nextChar];
            [d appendBytes:(unsigned char*)">>" length:2];
            next = [self nextChar];
        } else {
            [d appendBytes:(unsigned char*)&next length:1];
            next = [self nextChar];
        }
    }
    // return dictionary without << and >>
    return [NSData dataWithBytes:[d bytes] + 2 length:[d length] - 4];
}

- (NSData *)getStreamContent:(int)ret {
    unsigned int start = 0;
    unsigned int len = 1; // start with len in 1
    unsigned char next = 0;
    if (ret == kTWO_END_LINE_MARKERS) {
        next = [self nextChar];
        start = pos; // pos: the current position of stream
    }
    
    if (ret == kONE_END_LINE_MARKER) {
        start = pos; // pos: the current position of stream
        next = [self currentChar];
    }
    
    NSMutableString *endStream = [NSMutableString string];
    NSString *endStreamMarker1 = [NSString stringWithFormat:@"%c%cendstream",
                                  kCARRIAGE_RETURN, kLINE_FEED];
    NSString *endStreamMarker2 = [NSString stringWithFormat:@"%cendstream",
                                  kLINE_FEED];
    while (!([endStream isEqualToString: endStreamMarker1] ||
             [endStream isEqualToString: endStreamMarker2]) ) {
        if (next == kCARRIAGE_RETURN && [self peekNextChar] == kLINE_FEED) {
            [endStream setString:[NSString stringWithFormat:@"%c%c", next,
                                  [self nextChar]]];
            len += 2;
        } else if(next == kLINE_FEED) {
            [endStream setString:[NSString stringWithFormat:@"%c", next]];
            len += 1;
        } else {
            [endStream appendFormat:@"%c", next];
            len += 1;
        }
        next = [self nextChar];
    }
    NSUInteger endStreamLength = [endStream length];
    return [NSData dataWithBytes:[[self stream] bytes] + start
                          length: len - endStreamLength - 1];
}

- (BOOL)matchEndObj {
    unsigned char ch = [self currentChar];
    NSMutableString *s = [NSMutableString string];
    [s appendFormat:@"%c", ch];
    NSUInteger i;
    for (i = 0; i < 5; i++) {
        ch = [self nextChar];
        [s appendFormat:@"%c", ch];
    }
    if ([s isEqualToString:@"endobj"]) {
        return YES;
    }
    return NO;
}

// Just get the content between `obj` and `endobj`
- (NSData *)getIndirectObjectContent{
    unsigned char ch = [self nextChar];
    unsigned int start = pos;
    unsigned int len = 1;
    while(true) {
        if (ch == 'e') {
            unsigned int keep = pos;
            if ([self matchEndObj]) {
                break;
            } else {
                pos = keep;
            }
        }
        ch = [self nextChar];
        len += 1;
    }
    pos += 1; // consume one char to take advance into later tokens
    return [NSData dataWithBytes:[[self stream] bytes] + start
                          length: len - 1];
}

- (GToken *)nextToken {
    // Consume white spaces before parsing token
    while (isWhiteSpace([self currentChar]) && pos < [[self stream] length] - 1) {
        [self nextChar];
    }
    unsigned char current = [self currentChar];
    unsigned int start = pos;
    
    GToken * token = [GToken token];
    if (pos == [[self stream] length] - 1) {
        [token setType: kEndToken];
        return token;
    }
    
    switch (current) {
        case 'R': // Indirect object reference
        {
            char next = [self nextChar];
            if (isWhiteSpace(next) || isDelimiter(next)) {
                [token setType:kRefToken];
                [token setContent:[NSData dataWithBytes:"R" length:1]];
            }
            break;
        }
        case 'n': // 'null'
            if ([self nextChar] == 'u' && [self nextChar] == 'l' &&
                [self nextChar] == 'l' && isWhiteSpace([self nextChar])){
                [token setType:kNullObjectToken];
                unsigned char* bytes = (unsigned char*)[stream bytes];
                NSData *d = [NSData dataWithBytes:bytes + start length:4];
                [token setContent:d];
            }
            break;
            
        case 'f': // 'false'
            if ([self nextChar] == 'a' && [self nextChar] == 'l'
               && [self nextChar] == 's'
               && [self nextChar] == 'e' && isWhiteSpace([self nextChar])){
                [token setType:kBooleanToken];
                unsigned char* bytes = (unsigned char*)[stream bytes];
                NSData *d = [NSData dataWithBytes:bytes + start length:5];
                [token setContent:d];
            }
            break;
            
        case 't': // 'true'
            if ([self nextChar] == 'r' && [self nextChar] == 'u'
                && [self nextChar] == 'e'
                && isWhiteSpace([self nextChar])) {
                [token setType:kBooleanToken];
                unsigned char* bytes = (unsigned char*)[stream bytes];
                NSData *d = [NSData dataWithBytes:bytes + start length:4];
                [token setContent:d];
            }
            break;
            
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case '+':
        case '-':
        case '.': // number
            [token setType:kNumberToken];
            [token setContent:[self getNumber]];
            break;
        
        case '(': // literal strings
            [token setType:kLiteralStringsToken];
            [token setContent:[self getLiteralStrings]];
            break;
 
        case '<': // hexadecimal strings
            if ([self nextChar] != '<') {
                [token setType:kHexadecimalStringsToken];
                [token setContent:[self getHexadecimalStrings]];
            } else {
                [token setType:kDictionaryObjectToken];
                [token setContent:[self getDictionary]];
            }
            break;
        
        case '/': // name object
            [token setType:kNameObjectToken];
            // [self getNameOriginal] must be called before [self getName]
            // Because we restore lexer's pos in former method
            [token setOriginalContent:[self getNameOriginal]];
            [token setContent:[self getName]];
            break;
        
        case '[':
            [token setType:kArrayObjectToken];
            [token setContent:[self getArray]];
            break;
        
        case 's':
            if ([self nextChar] == 't' && [self nextChar] == 'r'
                && [self nextChar] == 'e' && [self nextChar] == 'a'
                && [self nextChar] == 'm') {
                int ret = isEndLineMarker([self nextChar], [self nextChar]);
                if (ret !=  kNOT_END_LINE_MARKER) {
                    [token setType:kStreamContentToken];
                    unsigned int start = 0;
                    if (ret == kTWO_END_LINE_MARKERS) {
                        [self nextChar];
                        start = pos; // pos: the current position of stream
                    }
                    
                    if (ret == kONE_END_LINE_MARKER) {
                        start = pos; // pos: the current position of stream
                    }
                    [token setStartPos:start];
                }
            }
            break;
            
        case 'o':
            if ([self nextChar] == 'b' && [self nextChar] == 'j') {
                [token setType:kIndirectObjectContentToken];
                [token setStartPos:pos+1];
            }
            break;
            
        default:
            [token setType:kUnknownToken];
            break;
    }
    
    // If we get kUnknowToken here, we go back to token begining and
    // continue to get Command Token
    if ([token type] == kUnknownToken) {
        pos = start;
        current = [self currentChar];
        NSMutableData *data = [NSMutableData data];
        while(!isWhiteSpace(current)) {
            if (isDelimiter(current)) break;
            [data appendBytes:&current length:1];
            current = [self nextChar];
        }
        // TODO: Check if *data is a really command string, we assume it's
        // a command string without further checking by now
        [token setType:kCommandToken];
        [token setContent:data];
    }
    return token;
}

- (NSString*)nextLine {
    unsigned char current = [self currentChar];
    NSMutableString *s = [NSMutableString string];
    while (!(current == kCARRIAGE_RETURN || current == kLINE_FEED)) {
        [s appendFormat:@"%c", current];
        current = [self nextChar];
    }
    if ([self peekNextChar] == kLINE_FEED) {
        current = [self nextChar];
        [s appendFormat:@"%c", current];
    }
    [self nextChar];
    return s;
}
@end
