//
//  GColorSpaceTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 4/14/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "GColorSpace.h"
#import "GIndexedColorSpace.h"
#import "GAlternateColorSpace.h"
#import "GPage.h"
#import "GObjects.h"
#import "GDocument.h"

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
    
    // Construct GCommandObject to pass to mapColor:
    NSString *s = @"0 cs";
    GParser *p2 = [GParser parser];
    [p2 setStream:[s dataUsingEncoding:NSASCIIStringEncoding]];
    [p2 parse];
    NSArray *result = [p2 objects];
    GNumberObject *n = [result firstObject];
    GCommandObject *cmd = [result lastObject];
    
    NSArray *args = [NSArray arrayWithObjects:n, nil];
    [cmd setArgs:args];
    
    // Map color by using alternate color space
    NSColor *color = [alt mapColor:cmd];
    
    // Test
    NSColor *c = [NSColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    XCTAssertEqualObjects(color, c);
}

- (void)testGSeparationColorSpace {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSString *path = [bundle pathForResource:@"coders-at-work" ofType:@"pdf"];
    GDocument *doc = [[GDocument alloc] initWithFrame:NSZeroRect];
    
    [doc setFile:path];
    
    // Parse all pages
    [doc parsePages];
    
    GPage *firstPage = [[doc pages] firstObject];
    
    // Parse page content, plus resources dictionary, which is needed in this test
    [firstPage parsePageContent];
    
    GColorSpace *cs = [GColorSpace colorSpaceWithName:@"Cs8" page:firstPage];

    // Construct GCommandObject to pass to mapColor:
    NSString *s = @"0 cs";
    GParser *p2 = [GParser parser];
    [p2 setStream:[s dataUsingEncoding:NSASCIIStringEncoding]];
    [p2 parse];
    NSArray *result = [p2 objects];
    GNumberObject *n = [result firstObject];
    GCommandObject *cmd = [result lastObject];
    
    NSArray *args = [NSArray arrayWithObjects:n, nil];
    [cmd setArgs:args];
    
    // Map color by using alternate color space
    NSColor *color = [cs mapColor:cmd];
    
    NSColor *c = [NSColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    XCTAssertEqualObjects(color, c);
}

- (void)testColorSpaceNumComps {
    NSString *colorSpaceName = @"DeviceRGB";
    GPage *page = [GPage create];
    GColorSpace *rgb = [GColorSpace colorSpaceWithName:colorSpaceName page:page];
    XCTAssertEqual([rgb numComps], 3);
    
    colorSpaceName = @"DeviceGray";
    GColorSpace *gray = [GColorSpace colorSpaceWithName:colorSpaceName page:page];
    XCTAssertEqual([gray numComps], 1);
    
    /* GAlternateColorSpace */
    GParser *p = [GParser parser];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSString *path = [bundle pathForResource:@"type0_function" ofType:@"bin"];
    NSData *d = [NSData dataWithContentsOfFile:path];
    NSMutableData *m = [NSMutableData data];
    [m appendData:d];
    [m appendBytes:"\0" length:1];
    [p setStream:d];
    [p parse];
    
    GStreamObject *streamObj = [[p objects] firstObject];
    
    GFunction *function = [GFunction functionWithStreamObject:streamObj];
    
    GColorSpace *cs = [GColorSpace colorSpaceWithName:@"DeviceRGB" page:page];
    
    GAlternateColorSpace *alt = [GAlternateColorSpace colorSpace:cs function:function];
    
    XCTAssertEqual([alt numComps], 3);
}

- (void)testGIndexedColorSpace {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSString *path = [bundle pathForResource:@"coders-at-work" ofType:@"pdf"];
    GDocument *doc = [[GDocument alloc] initWithFrame:NSZeroRect];
    
    [doc setFile:path];
    
    // Parse all pages
    [doc parsePages];
    
    GPage *firstPage = [[doc pages] firstObject];
    
    // Parse page content, plus resources dictionary, which is needed in this test
    [firstPage parsePageContent];
    
    GColorSpace *cs = [GColorSpace colorSpaceWithName:@"Cs11" page:firstPage];

    NSData *lookupTable = [(GIndexedColorSpace*)cs lookupTable];
    int numComps = [(GIndexedColorSpace*)cs numComps];
    int hival = [(GIndexedColorSpace*)cs hival];
    int length = numComps * (hival + 1);
    XCTAssertEqual([lookupTable length], length);
    
    // Test color
    // Construct GCommandObject to pass to mapColor:
    NSString *s = @"0 cs";
    GParser *p2 = [GParser parser];
    [p2 setStream:[s dataUsingEncoding:NSASCIIStringEncoding]];
    [p2 parse];
    NSArray *result = [p2 objects];
    GNumberObject *n = [result firstObject];
    GCommandObject *cmd = [result lastObject];
    
    NSArray *args = [NSArray arrayWithObjects:n, nil];
    [cmd setArgs:args];
    
    // Map color by using GIndexed color space
    NSColor *color = [cs mapColor:cmd];
    
    NSColor *c = [NSColor colorWithRed:0.317647 green:0.317647 blue:0.317647 alpha:1.0];
    XCTAssertEqualObjects(color, c);
}

@end
