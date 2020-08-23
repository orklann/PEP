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

- (void)testGLexerNextTokenBooleanToken {
    // #1 Test boolean: "false" from "false"
    GLexer *l = [GLexer lexer];
    char *b = "false";
    NSData *d = [NSData dataWithBytes:b length:6];
    NSData *falseData = [NSData dataWithBytes:"false" length:5];
    [l setStream:d];
    GToken *t = [l nextToken];
    XCTAssertEqual([t type], kBooleanToken);
    XCTAssertEqualObjects([t content], falseData);
    
    // #2 Test boolean: "false" from "false "
    GLexer *l2 = [GLexer lexer];
    char *b2 = "false ";
    NSData *d2 = [NSData dataWithBytes:b2 length:6];
    NSData *falseData2 = [NSData dataWithBytes:"false" length:5];
    [l2 setStream:d2];
    GToken *t2 = [l2 nextToken];
    XCTAssertEqual([t2 type], kBooleanToken);
    XCTAssertEqualObjects([t2 content], falseData2);
    
    // #3 Test boolean: "true" from "true"
    GLexer *l3 = [GLexer lexer];
    char *b3 = "true";
    NSData *d3 = [NSData dataWithBytes:b3 length:5];
    NSData *trueData = [NSData dataWithBytes:"true" length:4];
    [l3 setStream:d3];
    GToken *t3 = [l3 nextToken];
    XCTAssertEqual([t3 type], kBooleanToken);
    XCTAssertEqualObjects([t3 content], trueData);
    
    // #4 Test boolean: "true" from "true "
    GLexer *l4 = [GLexer lexer];
    char *b4 = "true ";
    NSData *d4 = [NSData dataWithBytes:b4 length:5];
    NSData *trueData2 = [NSData dataWithBytes:"true" length:4];
    [l4 setStream:d4];
    GToken *t4 = [l4 nextToken];
    XCTAssertEqual([t4 type], kBooleanToken);
    XCTAssertEqualObjects([t4 content], trueData2);
    
    // #5 Test boolean: "true", "false" from "true false"
    GLexer *l5 = [GLexer lexer];
    char *b5 = "true false";
    NSData *d5 = [NSData dataWithBytes:b5 length:11];
    [l5 setStream:d5];
    GToken *t5 = [l5 nextToken];
    XCTAssertEqual([t5 type], kBooleanToken);
    XCTAssertEqualObjects([t5 content], trueData);
    GToken *t6 = [l5 nextToken];
    XCTAssertEqual([t6 type], kBooleanToken);
    XCTAssertEqualObjects([t6 content], falseData);
}
@end
