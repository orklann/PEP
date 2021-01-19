//
//  GObjects.m
//  PEP
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GObjects.h"
#import "GParser.h"
#import "GDecoders.h"

NSArray *getCommandArgs(NSArray *objects, unsigned int argsNumber) {
    NSMutableArray *ret = [NSMutableArray array];
    unsigned int start = (unsigned int)[objects count] - argsNumber;
    NSUInteger i;
    for (i = start; i < start + argsNumber; i++) {
        [ret addObject:[objects objectAtIndex:i]];
    }
    return ret;
}

NSArray *getDynamicCommandArgs(NSArray *objects) {
    NSMutableArray *ret = [NSMutableArray array];
    NSInteger i = [objects count] - 1;
    id obj = [objects objectAtIndex:i];
    [ret addObject:obj];
    while ([(GObject*)obj type] != kCommandObject && i >= 0 ) {
        [ret addObject:obj];
        obj = [objects objectAtIndex:i];
        i -= 1;
    }
    return ret;
}

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

- (NSString*)toString {
    NSString *ret = @"true";
    if (value) {
        ret = @"true";
    } else {
        ret = @"false";
    }
    return ret;
}
@end

@implementation GNumberObject
+ (id)create {
    GNumberObject *o = [[GNumberObject alloc] init];
    return o;
}

- (void)setSubtype:(NumberSubtype)s {
    subtype = s;
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

- (double)getRealValue {
    double ret = 0.0;
    if (subtype == kIntSubtype){
        ret = (double)intValue;
    } else if (subtype == kRealSubtype) {
        ret = realValue;
    }
    return ret;
}

- (NSString*)toString {
    NSString *ret = @"";
    if (subtype == kIntSubtype) {
        ret = [NSString stringWithFormat:@"%d", intValue];
    } else if (subtype == kRealSubtype) {
        ret = [NSString stringWithFormat:@"%.6f", realValue];
    }
    return ret;
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

- (NSString*)toString {
    return [NSString stringWithFormat:@"(%@)", value];
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
        unsigned char v = (unsigned char)result;
        // TODO: Test for "bug_hex_string.pdf"
        //sprintf((char *)&v, "%c", (unsigned char)result);
        [d appendBytes:&v length:1];
        [self nextChar];
    }
    value = (NSData*)d;
}

- (NSString*)stringValue {
    return [[NSString alloc] initWithData:value encoding:NSASCIIStringEncoding];
}

- (NSString*)toString {
    NSMutableString *ret = [NSMutableString string];
    [ret appendString:@"<"];
    [ret appendString:[[NSString alloc] initWithData:rawContent encoding:NSASCIIStringEncoding]];
    [ret appendString:@">"];
    return ret;
}
    
@end

@implementation GNameObject

+ (id)create {
    GNameObject *o = [[GNameObject alloc] init];
    return o;
}

- (void)setLexerRawContent:(NSData*)d {
    lexerRawContent = d;
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

- (NSString*)toString {
    NSString *rawString =  [[NSString alloc] initWithData:lexerRawContent
                                                 encoding:NSASCIIStringEncoding];
    return [NSString stringWithFormat:@"/%@", rawString];
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
    NSMutableData *d = [NSMutableData dataWithBytes:[rawContent bytes]
                                             length:[rawContent length]];
    // End stream with '\0' to ensure it will stop parsing
    // Because GLexer need '\0' at the end to generate kEndToken
    [d appendBytes:"\0" length:1];
    [p setStream:d];
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

- (NSString*)getRawContentString {
    NSMutableString *s = [NSMutableString string];
    [s appendString:@"<< "];
    [s appendString:[[NSString alloc] initWithData:rawContent encoding:NSASCIIStringEncoding]];
    [s appendString:@" >>"];
    return s;
}

- (NSString*)toString {
    NSMutableString *ret = [NSMutableString string];
    [ret appendString:@"<<"];
    int i;
    for (i = 0; i < [[value allKeys] count]; i++) {
        NSString *key = [[value allKeys] objectAtIndex:i];
        GObject *o = (GObject*)[value objectForKey:key];
        if (i != 0) {
            [ret appendString:@" "];
        }
        
        [ret appendFormat:@"/%@ ", key];
        if ([o type] == kBooleanObject) {
            [ret appendFormat:@"%@", [(GBooleanObject*)o toString]];
        } else if ([o type] == kNumberObject) {
            [ret appendFormat:@"%@", [(GNumberObject*)o toString]];
        } else if ([o type] == kLiteralStringsObject) {
            [ret appendFormat:@"%@", [(GLiteralStringsObject*)o toString]];
        } else if ([o type] == kHexStringsObject) {
            [ret appendFormat:@"%@", [(GHexStringsObject*)o toString]];
        } else if ([o type] == kNameObject) {
            [ret appendFormat:@"%@", [(GNameObject*)o toString]];
        } else if ([o type] == kArrayObject) {
            [ret appendFormat:@"%@", [(GArrayObject*)o toString]];
        } else if ([o type] == kNullObject) {
            [ret appendFormat:@"%@", [(GNullObject*)o toString]];
        } else if ([o type] == kDictionaryObject) {
            [ret appendFormat:@"%@", [(GDictionaryObject*)o toString]];
        } else if ([o type] == kRefObject) {
            [ret appendFormat:@"%@", [(GRefObject*)o toString]];
        }
    }
    [ret appendFormat:@">>"];
    return ret;
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
    NSMutableData *d = [NSMutableData dataWithBytes:[rawContent bytes]
                                             length:[rawContent length]];
    // End stream with '\0' to ensure it will stop parsing
    // Because GLexer need '\0' at the end to generate kEndToken
    [d appendBytes:"\0" length:1];
    [p setStream:d];
    [p parse];
    value = [p objects];
}

- (NSString*)toString {
    NSMutableString *ret = [NSMutableString string];
    [ret appendString:@"["];
    int i;
    for (i = 0; i < [value count]; i++) {
        GObject *o = (GObject*)[value objectAtIndex:i];
        if (i != 0) {
            [ret appendString:@" "];
        }
        
        if ([o type] == kBooleanObject) {
            [ret appendFormat:@"%@", [(GBooleanObject*)o toString]];
        } else if ([o type] == kNumberObject) {
            [ret appendFormat:@"%@", [(GNumberObject*)o toString]];
        } else if ([o type] == kLiteralStringsObject) {
            [ret appendFormat:@"%@", [(GLiteralStringsObject*)o toString]];
        } else if ([o type] == kHexStringsObject) {
            [ret appendFormat:@"%@", [(GHexStringsObject*)o toString]];
        } else if ([o type] == kNameObject) {
            [ret appendFormat:@"%@", [(GNameObject*)o toString]];
        } else if ([o type] == kArrayObject) {
            [ret appendFormat:@"%@", [(GArrayObject*)o toString]];
        } else if ([o type] == kNullObject) {
            [ret appendFormat:@"%@", [(GNullObject*)o toString]];
        } else if ([o type] == kDictionaryObject) {
            [ret appendFormat:@"%@", [(GDictionaryObject*)o toString]];
        } else if ([o type] == kRefObject) {
            [ret appendFormat:@"%@", [(GRefObject*)o toString]];
        }
    }
    [ret appendFormat:@"]"];
    return ret;
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
    id value = [[dictionary value] objectForKey:@"Length"];
    int len = 0;
    if ([(GObject*)value type] == kNumberObject) {
        len = [(GNumberObject*)[[dictionary value] objectForKey:@"Length"] intValue];
    } else if ([(GObject*)value type] == kRefObject) {
        GRefObject* ref = (GRefObject*)value;
        GNumberObject *lenObject = [self.parser getObjectByRef:[ref getRefString]];
        len = [lenObject intValue];
    }

    GLexer *l = [self.parser lexer];
    // Parse stream content, we also modify lexers pos
    char *bytes = (char*)[[l stream] bytes];
    streamContent = [NSData dataWithBytes:(char*)(bytes + self.startContentPos) length:len];
    [l setPos:self.startContentPos + len];
    char next = [l nextChar];
    while (next != 'm') { // `m` at the end of `endstream`
        next = [l nextChar];
    }
    next = [l nextChar];
}

- (NSData*)getDecodedStreamContent {
    NSData *decodedData;
    id decodeMethod = [[dictionary value] objectForKey:@"Filter"];
    if ([(GObject*)decodeMethod type] == kNameObject) { // Single filter here
        if ([[(GNameObject*)decodeMethod value] isEqualToString:@"FlateDecode"]) {
            decodedData = decodeFlate(streamContent);
        }
    } else if ([(GObject*)decodeMethod type] == kArrayObject) { // Multiple filters
        GArrayObject *filters = (GArrayObject*)decodeMethod;
        decodedData = streamContent;
        for (GNameObject *decoder in [filters value]) {
            if ([[decoder value]
                 isEqualToString:@"ASCII85Decode"]) {
                decodedData = decodeASCII85(decodedData);
            } else if ([[decoder value]
                        isEqualToString:@"FlateDecode"]){
                decodedData = decodeFlate(decodedData);
            }
        }
    }
    return decodedData;
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
    GParser *p = [self parser];
    [[p lexer] setPos:self.startPos];
    // Indirect object only contains one object
    object = [p parseNextObject];
}
@end

@implementation GNullObject
+ (id)create {
    GNullObject *o = [[GNullObject alloc] init];
    return o;
}

- (NSString*)toString {
    return @"null";
}
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

- (NSString*)getRefString {
    NSString *refString = [NSString stringWithFormat:@"%d-%d",
                            [self objectNumber],
                            [self generationNumber]];
    return refString;
}

- (NSString*)toString {
    NSString *refString = [NSString stringWithFormat:@"%d %d R",
                            [self objectNumber],
                            [self generationNumber]];
    return refString;
}
@end

@implementation GEndObject

@end

@implementation GXRefEntry
+ (id)create {
    id o = [[GXRefEntry alloc] init];
    return o;
}

- (void)setObjectNumber:(unsigned int)n {
    objectNumber = n;
}

- (unsigned int)objectNumber {
    return objectNumber;
}

- (void)setOffset:(unsigned int)os {
    offset = os;
}

- (unsigned int)offset {
    return offset;
}

- (void)setGenerationNumber:(unsigned int)g {
    generationNumber = g;
}

- (unsigned int)generationNumber {
    return generationNumber;
}

- (void)setInUse:(unsigned char)i {
    inUse = i;
}

- (unsigned char)inUse {
    return inUse;
}
@end

@implementation GCommandObject
+ (id)create {
    id o = [[GCommandObject alloc] init];
    [o setType:kCommandObject];
    return o;
}

- (void)setCmd:(NSString *)c {
    cmd = c;
}

- (NSString *)cmd {
    return cmd;
}

- (void)setArgs:(NSArray *)a {
    args = a;
}

- (NSArray*)args {
    return args;
}

- (void)parse {
    
}
@end
