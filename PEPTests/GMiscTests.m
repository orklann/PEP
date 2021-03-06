//
//  GMiscTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 10/22/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GBinaryData.h"
#import "GMisc.h"

@interface GMiscTests : XCTestCase

@end

@implementation GMiscTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSortedGBinaryDataArray {
    NSMutableArray *array = [NSMutableArray array];
    GBinaryData *one = [GBinaryData create];
    one.objectNumber = 2;
    GBinaryData *two = [GBinaryData create];
    two.objectNumber = 1;
    [array addObject:one];
    [array addObject:two];
    
    NSMutableArray *sorted = sortedGBinaryDataArray(array);
    GBinaryData *first = [sorted firstObject];
    GBinaryData *second = [sorted objectAtIndex:1];
    XCTAssertEqual(first.objectNumber, 1);
    XCTAssertEqual(second.objectNumber, 2);
}

- (void)testPaddingTenZero {
    int offset = 1;
    NSString *one = paddingTenZero(offset);
    XCTAssertEqualObjects(one, @"0000000001");
    offset = 12345;
    NSString *two = paddingTenZero(offset);
    XCTAssertEqualObjects(two, @"0000012345");
}

- (void)testPaddingFiveZero {
    int number = 1;
    NSString *one = paddingFiveZero(number);
    XCTAssertEqualObjects(one, @"00001");
    
    number = 0;
    NSString *two = paddingFiveZero(number);
    XCTAssertEqualObjects(two, @"00000");
}

- (void)testGetObjectNumber {
    NSString *ref = @"1-0";
    int objectNumber = getObjectNumber(ref);
    XCTAssertEqual(objectNumber, 1);
}

- (void)testGetGenerationNumber {
    NSString *ref = @"1-0";
    int generationNumber = getGenerationNumber(ref);
    XCTAssertEqual(generationNumber, 0);
}
@end
