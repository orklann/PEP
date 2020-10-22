//
//  GObjectsTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 10/22/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GParser.h"
#import "GObjects.h"

@interface GObjectsTests : XCTestCase

@end

@implementation GObjectsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGBooleanObjectToString {
    GParser *p = [GParser parser];
    char *b = "false true";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    
    GBooleanObject *f = [objs firstObject];
    XCTAssertEqualObjects([f toString], @"false");
    
    GBooleanObject *t = [objs lastObject];
    XCTAssertEqualObjects([t toString], @"true");
}
@end
