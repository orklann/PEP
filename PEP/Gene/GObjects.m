//
//  GObjects.m
//  PEP
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GObjects.h"

@implementation GBooleanObject
+ (id)create {
    GBooleanObject *o = [[GBooleanObject alloc] init];
    return o;
}

- (void)setType:(int)t {
    type = t;
}

- (int)type {
    return type;
}

- (void)setValue:(BOOL)v {
    value = v;
}

- (BOOL)value {
    return value;
}

- (void)setRawContent:(NSData*)d {
    rawContent = d;
}

- (NSData *)rawContent {
    return rawContent;
}
@end
