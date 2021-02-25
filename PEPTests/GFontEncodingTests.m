//
//  GFontEncodingTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 2/25/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GFontEncoding.h"
#import "GParser.h"

@interface GFontEncodingTests : XCTestCase

@end

@implementation GFontEncodingTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testParseDifference {
    GParser *p = [GParser parser];
    char *s = "[174 /AE /Oslash 177 /plusminus 180 /yen /mu]";
    NSData *d = [NSData dataWithBytes:s length:strlen(s) + 1];
    [p setStream:d];
    GArrayObject *array = [p parseNextObject];
    
    GFontEncoding *fe = [GFontEncoding create];
    [fe parseDifference:array];
    
    NSString *name;
    name = [fe getGlyphNameInDifference:174];
    XCTAssertEqualObjects(name, @"AE");
    
    name = [fe getGlyphNameInDifference:175];
    XCTAssertEqualObjects(name, @"Oslash");
    
    name = [fe getGlyphNameInDifference:177];
    XCTAssertEqualObjects(name, @"plusminus");
    
    name = [fe getGlyphNameInDifference:180];
    XCTAssertEqualObjects(name, @"yen");
    
    name = [fe getGlyphNameInDifference:181];
    XCTAssertEqualObjects(name, @"mu");
    
    // name should be nil
    name = [fe getGlyphNameInDifference:199];
    XCTAssertEqualObjects(name, nil);
}

@end
