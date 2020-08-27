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
@end
