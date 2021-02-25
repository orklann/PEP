//
//  GFontInfoTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 2/16/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GFontInfo.h"


@interface GFontInfoTests : XCTestCase

@end

@implementation GFontInfoTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGetCharWidth {
    NSMutableArray *array = [NSMutableArray array];
    NSNumber *n1 = [NSNumber numberWithInt:500];
    NSNumber *n2 = [NSNumber numberWithInt:250];
    [array addObject:n1];
    [array addObject:n2];
    GFontInfo *fontInfo = [GFontInfo create];
    [fontInfo setFirstChar:32];
    [fontInfo setWidths:array];
    
    unichar ch = 0x20;
    CGFloat width = [fontInfo getCharWidth:ch];
    XCTAssertEqual(width, 0.5);
    ch = ch + 1;
    width = [fontInfo getCharWidth:ch];
    XCTAssertEqual(width, 0.25);
}
@end
