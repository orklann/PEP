//
//  GLexerTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 8/22/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GLexer.h"

@interface GLexerTests : XCTestCase

@end

@implementation GLexerTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGLexerSetStream {
    GLexer *l = [GLexer lexer];
    char *b = "HELLO, LEXER";
    NSData *d = [NSData dataWithBytes:b length:13];
    [l setStream:d];
    XCTAssertEqualObjects(d, [l stream]);
}

- (void)testGLexerNextChar {
    GLexer *l = [GLexer lexer];
    char *b = "ABCDE";
    NSData *d = [NSData dataWithBytes:b length:13];
    [l setStream:d];
    XCTAssertEqual([l nextChar], 'B');
    XCTAssertEqual([l nextChar], 'C');
    XCTAssertEqual([l nextChar], 'D');
    XCTAssertEqual([l nextChar], 'E');
}
@end
