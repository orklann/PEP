//
//  GColorSpaceTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 4/14/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "GColorSpace.h"
#import "GAlternateColorSpace.h"
#import "GPage.h"
#import "GObjects.h"

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

- (void)testGDeviceRGBColorSpace {
    NSString *colorSpaceName = @"DeviceRGB";
    GPage *page = [GPage create];
    GColorSpace *cs = [GColorSpace colorSpaceWithName:colorSpaceName page:page];
    XCTAssertEqualObjects([cs className], @"GDeviceRGBColorSpace");
}

- (void)testGDeviceRGBColorSingleton {
    NSString *colorSpaceName = @"DeviceRGB";
    GPage *page = [GPage create];
    GColorSpace *cs1 = [GColorSpace colorSpaceWithName:colorSpaceName page:page];
    GColorSpace *cs2 = [GColorSpace colorSpaceWithName:colorSpaceName page:page];
    XCTAssertEqualObjects(cs1, cs2);
}

- (void)testGAlternateColorSpace {
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
    
    GPage *page = [GPage create];
    GColorSpace *cs = [GColorSpace colorSpaceWithName:@"DeviceRGB" page:page];
    
    GAlternateColorSpace *alt = [GAlternateColorSpace colorSpace:cs function:function];
    
    // Turns array of NSNumber into GNumberObject
    NSString *s = @"0 cs";
    GParser *p2 = [GParser parser];
    [p2 setStream:[s dataUsingEncoding:NSASCIIStringEncoding]];
    [p2 parse];
    NSArray *result = [p2 objects];
    GNumberObject *n = [result firstObject];
    GCommandObject *cmd = [result lastObject];
    
    NSArray *args = [NSArray arrayWithObjects:n, nil];
    [cmd setArgs:args];
    
    NSColor *color = [alt mapColor:cmd];
    
    // Test
    NSColor *c = [NSColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    XCTAssertEqualObjects(color, c);
}
@end
