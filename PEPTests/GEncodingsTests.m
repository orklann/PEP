//
//  GEncodingsTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 2/4/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GEncodings.h"

@interface GEncodingsTests : XCTestCase

@end

@implementation GEncodingsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGEncodings1 {
    char *space = MacRomanEncoding[32];
    NSString *test = @"space";
    NSString *result = [NSString stringWithFormat:@"%s", space];
    XCTAssertEqualObjects(result, test);
    
    char *a = MacRomanEncoding[97];
    test = @"a";
    result = [NSString stringWithFormat:@"%s", a];
    XCTAssertEqualObjects(result, test);
}

@end
