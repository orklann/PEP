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

- (void)testGLexerCurrentChar {
    GLexer *l = [GLexer lexer];
    char *b = "ABCDE";
    NSData *d = [NSData dataWithBytes:b length:6];
    [l setStream:d];
    XCTAssertEqual([l currentChar], 'A');
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

- (void)testGLexerNextTokenNumberToken {
    GLexer *l = [GLexer lexer];
    char *b = "123 43445 +17 -98 0 34.5 -3.62 +123.6 4. -.002 0.0";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    NSData *d1 = [NSData dataWithBytes:"123" length:3];
    NSData *d2 = [NSData dataWithBytes:"43445" length:5];
    NSData *d3 = [NSData dataWithBytes:"+17" length:3];
    NSData *d4 = [NSData dataWithBytes:"-98" length:3];
    NSData *d5 = [NSData dataWithBytes:"0" length:1];
    NSData *d6 = [NSData dataWithBytes:"34.5" length:4];
    NSData *d7 = [NSData dataWithBytes:"-3.62" length:5];
    NSData *d8 = [NSData dataWithBytes:"+123.6" length:6];
    NSData *d9 = [NSData dataWithBytes:"4." length:2];
    NSData *d10 = [NSData dataWithBytes:"-.002" length:5];
    NSData *d11 = [NSData dataWithBytes:"0.0" length:3];
    [l setStream:d];
    GToken *t = [l nextToken];
    XCTAssertEqual([t type], kNumberToken);
    XCTAssertEqualObjects([t content], d1);
    XCTAssertNotEqualObjects([t content], [NSData dataWithBytes:"1000" length:4]);
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d2);
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d3);
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d4);
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d5);
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d6);
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d7);
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d8);
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d9);
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d10);
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d11);
}

- (void)testGLexerNextTokenLiteralStringsToken {
    GLexer *l = [GLexer lexer];
    char *b = "(This is a string)";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    NSData *d1 = [NSData dataWithBytes:"This is a string"
                                length:strlen("This is a string")];
    [l setStream:d];
    GToken *t = [l nextToken];
    XCTAssertEqual([t type], kLiteralStringsToken);
    XCTAssertEqualObjects([t content], d1);
    
    GLexer *l2 = [GLexer lexer];
    char *b2 = "(This is (a) () string)";
    NSData *d2 = [NSData dataWithBytes:b2 length:strlen(b2) + 1];
    NSData *d3 = [NSData dataWithBytes:"This is (a) () string"
                                length:strlen("This is (a) () string")];
    [l2 setStream:d2];
    GToken *t2 = [l2 nextToken];
    XCTAssertEqual([t2 type], kLiteralStringsToken);
    XCTAssertEqualObjects([t2 content], d3);
}

- (void)testGLexerNextTokenHexadecimalStringsToken{
    GLexer *l = [GLexer lexer];
    char *b = "<AAFFDE34F>";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    NSData *d1 = [NSData dataWithBytes:"AAFFDE34F0"
                                length:strlen("AAFFDE34F0")];
    [l setStream:d];
    GToken *t = [l nextToken];
    XCTAssertEqual([t type], kHexadecimalStringsToken);
    XCTAssertEqualObjects([t content], d1);
    
    b = "<AAFFDE34FE>";
    d = [NSData dataWithBytes:b length:strlen(b) + 1];
    d1 = [NSData dataWithBytes:"AAFFDE34FE"
                                length:strlen("AAFFDE34FE")];
    [l setStream:d];
    t = [l nextToken];
    XCTAssertEqual([t type], kHexadecimalStringsToken);
    XCTAssertEqualObjects([t content], d1);
    
}

- (void)testGLexerNextTokenNameObjectToken {
    GLexer *l = [GLexer lexer];
    char *b = "/Name1 /ASomewhatLongerName /A;Name_With-Various***Characters? /1.2 /$$ /@pattern /.notdef /Lime#20Green /paired#28#29parentheses /The_Key_of_F#23_Minor /A#42 /";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    NSData *d1 = [NSData dataWithBytes:"Name1"
                                length:strlen("Name1")];
    NSData *d2 = [NSData dataWithBytes:"ASomewhatLongerName"
                                length:strlen("ASomewhatLongerName")];
    NSData *d3 = [NSData dataWithBytes:"A;Name_With-Various***Characters?"
                                length:strlen("A;Name_With-Various***Characters?")];
    NSData *d4 = [NSData dataWithBytes:"1.2"
                                length:strlen("1.2")];
    NSData *d5 = [NSData dataWithBytes:"$$"
                                length:strlen("$$")];
    NSData *d6 = [NSData dataWithBytes:"@pattern"
                                length:strlen("@pattern")];
    NSData *d7 = [NSData dataWithBytes:".notdef"
                                length:strlen(".notdef")];
    NSData *d8 = [NSData dataWithBytes:"Lime Green"
                                length:strlen("Lime Green")];
    NSData *d9 = [NSData dataWithBytes:"paired()parentheses"
                                length:strlen("paired()parentheses")];
    NSData *d10 = [NSData dataWithBytes:"The_Key_of_F#_Minor"
                                length:strlen("The_Key_of_F#_Minor")];
    NSData *d11 = [NSData dataWithBytes:"AB"
                                length:strlen("AB")];
    NSData *d12 = [NSData dataWithBytes:""
                                 length:strlen("")];
    [l setStream:d];
    GToken *t = [l nextToken];
    XCTAssertEqual([t type], kNameObjectToken);
    XCTAssertEqualObjects([t content], d1);
    
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d2);
    
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d3);
    
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d4);
    
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d5);
    
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d6);
    
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d7);
    
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d8);
    
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d9);
    
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d10);
    
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d11);
    
    t = [l nextToken];
    XCTAssertEqualObjects([t content], d12);
}

- (void)testGLexerNextTokenArrayObjectToken {
    GLexer *l = [GLexer lexer];
    char *b = "[549 3.14 false (Ralph) /SomeName [123 3.14 (Jerry)]]";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    NSData *d1 = [NSData dataWithBytes:b
                                length:strlen(b)];
    [l setStream:d];
    GToken *t = [l nextToken];
    XCTAssertEqual([t type], kArrayObjectToken);
    XCTAssertEqualObjects([t content], d1);
}

- (void)testGLexerNextTokenDictionaryObjectToken {
    GLexer *l = [GLexer lexer];
    char *b = "<</Type /Example\n"
              "/Subtype /DictionaryExample\n"
              "/Version 0.01 /IntegerItem 12 /StringItem (a string)\n"
              "/Subdictionary <<\n"
                    "/Item1 0.4\n"
                    "/Item2 true\n"
                    "/LastItem (not !) /VeryLastItem (OK)\n"
                  ">>\n"
    ">> 123"; // "123" for testing
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    NSData *d1 = [NSData dataWithBytes:b
                                length:strlen(b) - 4];
    [l setStream:d];
    GToken *t = [l nextToken];
    XCTAssertEqual([t type], kDictionaryObjectToken);
    XCTAssertEqualObjects([t content], d1);
}

- (void)testGLexerNextTokenStreamContentToken {
    GLexer *l = [GLexer lexer];
    char *b = "stream\n"
              "I AM A STREAM CONTENT\n"
              "endstream";
    char *test1 = "I AM A STREAM CONTENT";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    NSData *d1 = [NSData dataWithBytes:test1
                                   length:strlen(test1)];
    [l setStream:d];
    GToken *t = [l nextToken];
    XCTAssertEqual([t type], kStreamContentToken);
    XCTAssertEqualObjects([t content], d1);
    
    b = "stream\r\n"
        "I AM A STREAM CONTENT\r\n"
        "endstream";
    d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [l setStream:d];
    t = [l nextToken];
    XCTAssertEqual([t type], kStreamContentToken);
    XCTAssertEqualObjects([t content], d1);
}

- (void)testGLexerNextTokenNullObjectToken {
    GLexer *l = [GLexer lexer];
    char *b = "null null";
    char *test1 = "null";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    NSData *d1 = [NSData dataWithBytes:test1
                                   length:strlen(test1)];
    [l setStream:d];
    GToken *t = [l nextToken];
    XCTAssertEqual([t type], kNullObjectToken);
    XCTAssertEqualObjects([t content], d1);
    
    t = [l nextToken];
    XCTAssertEqual([t type], kNullObjectToken);
    XCTAssertEqualObjects([t content], d1);
}
@end
