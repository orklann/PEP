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

@end
