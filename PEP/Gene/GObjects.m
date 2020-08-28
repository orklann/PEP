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

- (void)setType:(int)t {
    type = t;
}

- (int)type {
    return type;
}

- (void)setRawContent:(NSData*)d {
    rawContent = d;
}

- (NSData *)rawContent {
    return rawContent;
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

- (int)subtype {
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

- (int)getSubtype {
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
    if (st == kIntSubtype) {
        [d appendData:rawContent];
        [d appendBytes:"\0" length:1];
        NSString *s = [NSString stringWithUTF8String:[d bytes]];
        intValue = [s intValue];
    } else if (st == kRealSubtype) {
        
    }
    subtype = st;
}
@end
