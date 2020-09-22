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
    NSString *b = @"q Q q 72 361.6569 468 358.3431 re W n /Gs1 gs /Cs1 cs 1 1 1 sc "
                    "72 720 m 540 720 l";
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
    
    // cs
    GCommandObject *cs = [commands objectAtIndex:13];
    GNameObject *_Cs1 = [[cs args] firstObject];
    XCTAssertEqualObjects([_Cs1 value], @"Cs1");
    
    // sc
    GCommandObject *sc = [commands objectAtIndex:17];
    GNumberObject *_1 = [[sc args] firstObject];
    GNumberObject *_2 = [[sc args] objectAtIndex:1];
    GNumberObject *_3 = [[sc args] lastObject];
    
    XCTAssertEqual([_1 intValue], 1);
    XCTAssertEqual([_2 intValue], 1);
    XCTAssertEqual([_3 intValue], 1);
    
    // m
    GCommandObject *m = [commands objectAtIndex:20];
    GNumberObject *first = [[m args] firstObject];
    GNumberObject *last= [[m args] lastObject];
    XCTAssertEqual([first intValue], 72);
    XCTAssertEqual([last intValue], 720);
    
    // l
    GCommandObject *l = [commands objectAtIndex:23];
    first = [[l args] firstObject];
    last = [[l args] lastObject];
    XCTAssertEqual([first intValue], 540);
    XCTAssertEqual([last intValue], 720);
}
@end
