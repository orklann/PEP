//
//  GObjects.m
//  PEP
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GObjects.h"
#import "GParser.h"

@implementation GObject
+ (id)create {
    GObject *o = [[GObject alloc] init];
    return o;
}

- (void)setType:(ObjectType)t {
    type = t;
}

- (ObjectType)type {
    return type;
}

- (void)setRawContent:(NSData*)d {
    pos = 0;
    rawContent = d;
}

- (NSData *)rawContent {
    return rawContent;
}

- (unsigned char)currentChar {
    unsigned char *bytes = (unsigned char*)[rawContent bytes];
    return *(bytes + pos);
}

- (unsigned char)nextChar {
    unsigned char *bytes = (unsigned char*)[rawContent bytes];
    unsigned int len = (unsigned int)[rawContent length];
    if (pos + 1 <= len - 1){
        pos += 1;
    }
    return *(bytes + pos);
}

- (unsigned char)peekNextChar {
    unsigned char *bytes = (unsigned char*)[rawContent bytes];
    unsigned int len = (unsigned int)[rawContent length];
    int peekPos = pos;
    if (pos + 1 <= len - 1){
        peekPos = pos + 1;
    }
    return *(bytes + peekPos);
}

@end

@implementation GBooleanObject
+ (id)create {
    GBooleanObject *o = [[GBooleanObject alloc] init];
    return o;
}

- (void)setValue:(BOOL)v {
    value = v;
}

- (BOOL)value {
    return value;
}

- (void)parse {
     if ([rawContent isEqualToData:[NSData dataWithBytes:"false" length:5]]) {
         [self setValue:NO];
     } else if ([rawContent isEqualToData:[NSData dataWithBytes:"true" length:4]]) {
         [self setValue:YES];
     }
}
@end

@implementation GNumberObject
+ (id)create {
    GNumberObject *o = [[GNumberObject alloc] init];
    return o;
}

- (NumberSubtype)subtype {
    return subtype;
}

- (void)setIntValue:(int)v {
    intValue = v;
}

- (int)intValue {
    return intValue;
}

- (void)setRealValue:(double)v {
    realValue = v;
}

- (double)realValue {
    return realValue;
}

- (NumberSubtype)getSubtype {
    NSUInteger i;
    for (i = 0; i < [rawContent length]; i++) {
        if(*((unsigned char*)[rawContent bytes] + i) == '.') {
            return kRealSubtype;
        }
    }
    return kIntSubtype;
}

- (void)parse {
    int st = [self getSubtype];
    NSMutableData *d = [NSMutableData data];
    [d appendData:rawContent];
    [d appendBytes:"\0" length:1];
    NSString *s = [NSString stringWithUTF8String:[d bytes]];
    if (st == kIntSubtype) {
        intValue = [s intValue];
    } else if (st == kRealSubtype) {
        realValue = [s doubleValue];
    }
    subtype = st;
}
@end

@implementation GLiteralStringsObject

+ (id)create {
    GLiteralStringsObject *o = [[GLiteralStringsObject alloc] init];
    return o;
}

- (void)setValue:(NSString*)v {
    value = v;
}

- (NSString *)value {
    return value;
}

- (void)parse {
    NSMutableString *s = [NSMutableString string];
    unsigned char next = [self currentChar];
    while (next != '\0') {
        switch (next) {
            case '\\': // escape by '\'
            {
                next = [self nextChar];
                switch (next) {
                    case 'n': // 'n'
                    {
                        [s appendFormat:@"%c", '\n'];
                        next = [self nextChar];
                        break;
                    }
                    case 'r': // 'r'
                    {
                        [s appendFormat:@"%c", '\r'];
                        next = [self nextChar];
                        break;
                    }
                    case 't': // 't'
                    {
                        [s appendFormat:@"%c", '\t'];
                        next = [self nextChar];
                        break;
                    }
                    case 'b': // 'b'
                    {
                        [s appendFormat:@"%c", '\b'];
                        next = [self nextChar];
                        break;
                    }
                    case 'f': // 'f'
                    {
                        [s appendFormat:@"%c", '\f'];
                        next = [self nextChar];
                        break;
                    }
                    case '(': // '('
                    case ')': // ')'
                    case '\\':
                    {
                        [s appendFormat:@"%c", next];
                        next = [self nextChar];
                        break;
                    }
                    case '\r':
                    {
                        unsigned char ch2 = [self peekNextChar];
                        if (ch2 == '\n') {
                            next = [self nextChar];
                        }
                        next = [self nextChar];
                        break;
                    }
                    case '\n':
                    {
                        next = [self nextChar];
                        break;
                    }
                    case '0':
                    case '1':
                    case '2':
                    case '3':
                    case '4':
                    case '5':
                    case '6':
                    case '7':
                    {
                        NSMutableString *ddd = [NSMutableString string];
                        [ddd appendFormat:@"%c", next];
                        unsigned char ch1 = [self peekNextChar];
                        if (ch1 >= '0' && ch1 <= '7') {
                            [ddd appendFormat:@"%c", ch1];
                            next = [self nextChar];
                            unsigned char ch2 = [self peekNextChar];
                            if (ch2 >= '0' && ch2 <= '7') {
                                [ddd appendFormat:@"%c", ch2];
                                next = [self nextChar];
                            }
                        }
                        long result = strtol([ddd UTF8String], NULL, 8);
                        [s appendFormat:@"%c", (unsigned char)result];
                        next = [self nextChar];
                        break;
                    }
                    default:
                        break;
                }
            }
            default:
            {
                [s appendFormat:@"%c", next];
                break;
            }
        }
        next = [self nextChar];
    }
    
    value = (NSString *)s;
}
    
@end

@implementation GHexStringsObject

+ (id)create {
    GHexStringsObject *o = [[GHexStringsObject alloc] init];
    return o;
}

- (void)setValue:(NSData*)v {
    value = v;
}

- (NSData *)value {
    return value;
}

- (void)parse {
    unsigned long len = [rawContent length];
    NSMutableData *d = [NSMutableData data];
    while (pos + 1 < len) {
        unsigned char ch1 = [self currentChar];
        unsigned char ch2 = [self nextChar];
        NSString *s = [NSString stringWithFormat:@"%c%c", ch1, ch2];
        long result = strtol([s UTF8String], NULL, 16);
        unsigned char v[2];
        sprintf((char *)&v, "%c", (unsigned char)result);
        [d appendBytes:&v length:1];
        [self nextChar];
    }
    value = (NSData*)d;
}
    
@end

@implementation GNameObject

+ (id)create {
    GNameObject *o = [[GNameObject alloc] init];
    return o;
}

- (void)setValue:(NSString*)v {
    value = v;
}

- (NSString *)value {
    return value;
}

- (void)parse {
    NSMutableData* d = [NSMutableData dataWithBytes:[rawContent bytes]
                                      length:[rawContent length]];
    
    [d appendBytes:"\0" length:1];
    NSString *v = [NSString stringWithUTF8String:[d bytes]];
    value = v;
}
@end

@implementation GDictionaryObject

+ (id)create {
    GDictionaryObject *o = [[GDictionaryObject alloc] init];
    return o;
}

- (void)setValue:(NSMutableDictionary*)v {
    value = v;
}

- (NSMutableDictionary *)value {
    return value;
}

- (void)parse {
    GParser *p = [GParser parser];
    [p setStream:rawContent];
    [p parse];
    NSArray *array = [p objects];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSUInteger i;
    for (i = 0; i < [array count]; i = i + 2) {
        id key = [array objectAtIndex:i];
        if ([(GNameObject*)key type] != kNameObject) {
            NSException* errorKeyException = [NSException
                    exceptionWithName:@"DictionaryErrorKeyException"
                    reason:@"Dictionary key is not a name object!"
                    userInfo:nil];
            @throw errorKeyException;
            return ;
        }
        id v = [array objectAtIndex:i+1];
        [dict setValue:v forKey:[(GNameObject*)key value]];
    }
    value = dict;
}
@end

@implementation GArrayObject

+ (id)create {
    GArrayObject *o = [[GArrayObject alloc] init];
    return o;
}

- (void)setValue:(NSArray*)v {
    value = v;
}

- (NSArray *)value {
    return value;
}

- (void)parse {
    GParser *p = [GParser parser];
    [p setStream:rawContent];
    [p parse];
    value = [p objects];
}

@end

@implementation GStreamObject
+ (id)create {
    GStreamObject *o = [[GStreamObject alloc] init];
    return o;
}
- (void)setDictionaryObject:(GDictionaryObject*)d {
    dictionary = d;
}

- (GDictionaryObject *)dictionaryObject {
    return dictionary;
}

- (void)setStreamContent:(NSData *)c {
    streamContent = c;
}

- (NSData*)streamContent {
    return streamContent;
}

- (void)parse {
    // Just verify that stream content length is same as indicated in the
    // dictionary
    int len = [(GNumberObject*)[[dictionary value] objectForKey:@"Length"] intValue];
    if (len != [streamContent length]) {
        NSException* errorLengthException = [NSException
                exceptionWithName:@"StreamContentLengthErrorException"
                reason:@"Stream content length is not the same as indicated in dictionary"
                userInfo:nil];
        @throw errorLengthException;
        return ;
    }
}
@end

@implementation GIndirectObject

+ (id)create {
    GIndirectObject *o = [[GIndirectObject alloc] init];
    return o;
}

- (void)setObjectNumber:(int)n {
    objectNumber = n;
}

- (int)objectNumber {
    return objectNumber;
}

- (void)setGenerationNumber:(int)n {
    generationNumber = n;
}

- (int)generationNumber {
    return generationNumber;
}

- (void)setObject:(id)o {
    object = o;
}

- (id)object {
    return object;
}

- (void)parse {
    GParser *p = [GParser parser];
    [p setStream:rawContent];
    [p parse];
    
    // Indirect object only contains one object, which is the first one
    // from parser
    id firstObject = [[p objects] objectAtIndex:0];
    object = firstObject;
}
@end

@implementation GNullObject

@end

@implementation GRefObject

+ (id)create {
    GRefObject *o = [[GRefObject alloc] init];
    return o;
}

- (void)setObjectNumber:(int)n {
    objectNumber = n;
}

- (int)objectNumber {
    return objectNumber;
}

- (void)setGenerationNumber:(int)n {
    generationNumber = n;
}

- (int)generationNumber {
    return generationNumber;
}

- (void)parse {
    // Does nothing
}
@end
