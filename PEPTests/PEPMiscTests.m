//
//  PEPMiscTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 11/18/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PEPMisc.h"

@interface PEPMiscTests : XCTestCase

@end

@implementation PEPMiscTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGetFontPath {
    NSFont *font = [NSFont fontWithName:@"Gill Sans" size:1];
    NSString *fontPath = getFontPath(font);
    NSLog(@"Gill Sans font path: %@", fontPath);
}

@end
