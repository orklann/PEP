//
//  GFunctionsTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 4/28/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GFunction.h"
#import "GParser.h"

@interface GFunctionsTests : XCTestCase

@end

@implementation GFunctionsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGSampledFunction {
    GParser *p = [GParser parser];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    // Even test_xref.pdf is in the `pdf` folder, we still only need to provide
    // file name in the path, no need to provide folder name
    NSString *path = [bundle pathForResource:@"type0_function" ofType:@"bin"];
    NSData *d = [NSData dataWithContentsOfFile:path];
    NSMutableData *m = [NSMutableData data];
    [m appendData:d];
    [m appendBytes:"\0" length:1];
    [p setStream:d];
    [p parse];
    
    GStreamObject *streamObj = [[p objects] firstObject];
    
    GFunction *function = [GFunction functionWithStreamObject:streamObj];
    XCTAssertEqualObjects([function className], @"GSampledFunction");
}

@end
