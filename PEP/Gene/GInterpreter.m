//
//  GInterpreter.m
//  PEP
//
//  Created by Aaron Elkins on 9/21/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GInterpreter.h"
#import "GObjects.h"
#import "GMisc.h"

BOOL isCommand(NSString *cmd, NSString *cmd2) {
    return [cmd isEqualToString:cmd2];
}

@implementation GInterpreter
+ (id)create {
    GInterpreter *o = [[GInterpreter alloc] init];
    return o;
}

- (void)setParser:(GParser*)p {
    parser = p;
}

- (void)setInput:(NSData *)d {
    NSMutableData *data = [NSMutableData dataWithData:d];
    [data appendBytes:"\0" length:1];
    input = data;
}

- (void)parseCommamnds {
    commands = [NSMutableArray array];
    GParser *cmdParser = [GParser parser];
    [cmdParser setStream:input];
    id obj = [cmdParser parseNextObject];
    while([(GObject*)obj type] != kEndObject) {
        [commands addObject:obj];
        obj = [cmdParser parseNextObject];
    }
}

- (void)eval:(CGContextRef)context {
    [self parseCommamnds];
    NSLog(@"eval() %ld bytes in context: %@", [input length], context);
}
@end
