//
//  GObjects.m
//  PEP
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GObjects.h"

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
