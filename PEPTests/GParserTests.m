//
//  GLParserTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GParser.h"

@interface GLParserTests : XCTestCase

@end

@implementation GLParserTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGParserSetLexer {
    GParser *p = [GParser parser];
    GLexer *l = [GLexer lexer];
    [p setLexer:l];
    XCTAssertEqual([p lexer], l);
    
    GLexer *l2 = [GLexer lexer];
    XCTAssertNotEqual([p lexer], l2);
}
@end
