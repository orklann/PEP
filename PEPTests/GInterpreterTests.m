//
//  GInterpreterTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 9/22/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "GInterpreter.h"

@interface GInterpreterTests : XCTestCase

@end

@implementation GInterpreterTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testParseCommands {
    NSString *b = @"q Q q 72 361.6569 468 358.3431 re W n /Gs1 gs";
    NSData *data = [b dataUsingEncoding:NSASCIIStringEncoding];
    GInterpreter *interpreter = [GInterpreter create];
    [interpreter setInput:data];
    
    [interpreter parseCommands];
    NSArray *commands = [interpreter commands];
    
    // re
    GCommandObject *re = [commands objectAtIndex:7];
    GNumberObject *_72 = [[re args] firstObject];
    XCTAssertEqual([_72 intValue], 72);
    
    GNumberObject *lastArg = [[re args] lastObject];
    NSString* numberA = [NSString stringWithFormat:@"%.7f", [lastArg realValue]];
    NSString* numberB = [NSString stringWithFormat:@"%.7f", 358.3431];
    XCTAssertEqualObjects(numberA, numberB);
    
    // gs
    GCommandObject *gs = [commands objectAtIndex:11];
    GNameObject *_Gs1 = [[gs args] firstObject];
    XCTAssertEqualObjects([_Gs1 value], @"Gs1");
}
@end
