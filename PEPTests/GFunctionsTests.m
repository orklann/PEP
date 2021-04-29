//
//  GFunctionsTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 4/28/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GFunction.h"
#import "GSampledFunction.h"
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
    
    // Input size
    GSampledFunction *sampled = (GSampledFunction*)function;
    int inputSize = [sampled inputSize];
    XCTAssertEqual(inputSize, 1);
    
    // Domain
    NSArray *array = [[sampled domain] firstObject];
    XCTAssertEqual([[array firstObject] intValue], 0);
    XCTAssertEqual([[array lastObject] intValue], 1);
    
    // Output size
    int outputSize = [sampled outputSize];
    XCTAssertEqual(outputSize, 3);
    
    // Range
    NSArray *a1 = [[sampled range] firstObject];
    XCTAssertEqual([[a1 firstObject] intValue], 0);
    XCTAssertEqual([[a1 lastObject] intValue], 1);
    
    NSArray *a2 = [[sampled range] objectAtIndex:1];
    XCTAssertEqual([[a2 firstObject] intValue], 0);
    XCTAssertEqual([[a2 lastObject] intValue], 1);
    
    NSArray *a3 = [[sampled range] objectAtIndex:2];
    XCTAssertEqual([[a3 firstObject] intValue], 0);
    XCTAssertEqual([[a3 lastObject] intValue], 1);
    
    // Size
    NSArray *size = [sampled size];
    XCTAssertEqual([[size firstObject] intValue], 255);
    
    // bps
    int bps = [sampled bps];
    XCTAssertEqual(bps, 8);
    
    // Encode
    NSArray *encode = [sampled encode];
    NSArray *a4 = [encode firstObject];
    XCTAssertEqual([[a4 firstObject] intValue], 0);
    XCTAssertEqual([[a4 lastObject] intValue], 254);
    
    // Decode
    NSArray *decode = [sampled decode];
    NSArray *a5 = [decode firstObject];
    XCTAssertEqual([[a5 firstObject] intValue], 0);
    XCTAssertEqual([[a5 lastObject] intValue], 1);
    
    NSArray *a6 = [decode objectAtIndex:1];
    XCTAssertEqual([[a6 firstObject] intValue], 0);
    XCTAssertEqual([[a6 lastObject] intValue], 1);
    
    NSArray *a7 = [decode objectAtIndex:2];
    XCTAssertEqual([[a7 firstObject] intValue], 0);
    XCTAssertEqual([[a7 lastObject] intValue], 1);
    
    // Samples
    NSArray *samples = [sampled samples];
    XCTAssertEqual([samples count], 255 * 3);
    NSLog(@"%@", samples);
}

@end
