//
//  GEncodersTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 10/21/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GEncoders.h"
#import "GDecoders.h"

@interface GEncodersTests : XCTestCase

@end

@implementation GEncodersTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testEncodeFlate {
    NSString *s = @"PEP: PDF Editing Program";
    NSData *data = [NSData dataWithBytes:[s UTF8String] length:[s length]];
    NSData *encodedData = encodeFlate(data);
    NSData *decodedData = decodeFlate(encodedData);
    NSString *out = [[NSString alloc] initWithData:decodedData encoding:NSASCIIStringEncoding];
    XCTAssertEqualObjects(s, out);
}
@end
