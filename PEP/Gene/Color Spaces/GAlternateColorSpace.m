//
//  GAlternateColorSpace.m
//  PEP
//
//  Created by Aaron Elkins on 4/30/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GAlternateColorSpace.h"
#import "GObjects.h"
#import "GParser.h"

@implementation GAlternateColorSpace

+ (id)colorSpace:(GColorSpace*)base function:(GFunction*)fn {
    GAlternateColorSpace *cs = [[GAlternateColorSpace alloc] init];
    [cs setBaseColorSpace:base];
    [cs setFunction:fn];
    return cs;
}

- (NSColor*)mapColor:(GCommandObject*)cmd {
    NSArray *args = [cmd args];
    NSMutableArray *newArgs = [NSMutableArray array];
    for (GNumberObject *arg in args) {
        NSNumber *n = [NSNumber numberWithFloat:[arg getRealValue]];
        [newArgs addObject:n];
    }
    NSArray *result = [_function eval:newArgs];
    NSMutableString *ms = [NSMutableString string];
    for (NSNumber *n in result) {
        [ms appendFormat:@"%f ", [n floatValue]];
    }
    
    // Turns array of NSNumber into GNumberObject
    GParser *p = [GParser parser];
    [p setStream:[ms dataUsingEncoding:NSASCIIStringEncoding]];
    [p parse];
    result = [p objects];
    [cmd setArgs:result];
    
    return [_baseColorSpace mapColor:cmd];
}
@end
