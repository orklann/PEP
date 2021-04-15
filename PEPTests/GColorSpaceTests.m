//
//  GColorSpaceTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 4/14/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "GColorSpace.h"
#import "GPage.h"

@interface GColorSpaceTests : XCTestCase

@end

@implementation GColorSpaceTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGDeviceGrayColorSpace {
    NSString *colorSpaceName = @"DeviceGray";
    GPage *page = [GPage create];
    GColorSpace *cs = [GColorSpace colorSpaceWithName:colorSpaceName page:page];
    XCTAssertEqualObjects([cs className], @"GDeviceGrayColorSpace");
}

- (void)testGDeviceGrayColorSingleton {
    NSString *colorSpaceName = @"DeviceGray";
    GPage *page = [GPage create];
    GColorSpace *cs1 = [GColorSpace colorSpaceWithName:colorSpaceName page:page];
    GColorSpace *cs2 = [GColorSpace colorSpaceWithName:colorSpaceName page:page];
    XCTAssertEqualObjects(cs1, cs2);
}
@end
