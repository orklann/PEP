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
    NSData *d = [NSData dataWithBytes:b length:6];
    [l setStream:d];
    XCTAssertEqual([l nextChar], 'B');
    XCTAssertEqual([l nextChar], 'C');
    XCTAssertEqual([l nextChar], 'D');
    XCTAssertEqual([l nextChar], 'E');
    XCTAssertEqual([l nextChar], '\0');
    XCTAssertEqual([l nextChar], '\0');
    XCTAssertEqual([l nextChar], '\0');
}

- (void)testIsWhiteSpace {
    unsigned char ch = 0x00;
    XCTAssertTrue(isWhiteSpace(ch));
    ch = 0x09;
    XCTAssertTrue(isWhiteSpace(ch));
    ch = 0x0A;
    XCTAssertTrue(isWhiteSpace(ch));
    ch = 0x0C;
    XCTAssertTrue(isWhiteSpace(ch));
    ch = 0x0D;
    XCTAssertTrue(isWhiteSpace(ch));
    ch = 0x20;
    XCTAssertTrue(isWhiteSpace(ch));
    ch = 'A';
    XCTAssertFalse(isWhiteSpace(ch));
    ch = '\n';
    XCTAssertTrue(isWhiteSpace(ch));
    ch = '\r';
    XCTAssertTrue(isWhiteSpace(ch));
}

- (void)testGLexerPos {
    GLexer *l = [GLexer lexer];
    char *b = "ABCDE";
    NSData *d = [NSData dataWithBytes:b length:6];
    [l setStream:d];
    XCTAssertEqual([l pos], 0);
    [l nextChar];
    XCTAssertEqual([l pos], 1);
}

- (void)testGTokenSetType {
    GToken *t = [GToken token];
    [t setType: kBooleanToken];
    XCTAssertEqual([t type], kBooleanToken);
}
@end
