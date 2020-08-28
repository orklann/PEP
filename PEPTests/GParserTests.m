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

- (void)testGParserParseBooleanObject {
    GParser *p = [GParser parser];
    char *b = "false true";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    NSInteger i = 0;
    for (i = 0; i < [objs count]; i++) {
        if (i == 0) {
            GBooleanObject *obj = [objs objectAtIndex:i];
            XCTAssertEqual([obj value], NO);
            XCTAssertEqualObjects([obj rawContent], [NSData dataWithBytes:"false" length:5]);
        } else if (i == 1) {
            GBooleanObject *obj = [objs objectAtIndex:i];
            XCTAssertEqual([obj value], YES);
            XCTAssertEqualObjects([obj rawContent], [NSData dataWithBytes:"true" length:4]);
        }
    }
}

- (void)testGParserParseNumberObject {
    GParser *p = [GParser parser];
    char *b = "128 -128 .123 123. 3.14";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    NSInteger i = 0;
    for (i = 0; i < [objs count]; i++) {
        GNumberObject *obj = [objs objectAtIndex:i];
        if (i == 0) {
            XCTAssertEqual([obj subtype], kIntSubtype);
            XCTAssertEqual([obj intValue], 128);
        } else if (i == 1) {
            XCTAssertEqual([obj subtype], kIntSubtype);
            XCTAssertEqual([obj intValue], -128);
        } else if (i == 2) {
            XCTAssertEqual([obj subtype], kRealSubtype);
            NSString* numberA = [NSString stringWithFormat:@"%.6f", [obj realValue]];
            NSString* numberB = [NSString stringWithFormat:@"%.6f", .123];
            XCTAssertEqualObjects(numberA, numberB);
        } else if (i == 3) {
            XCTAssertEqual([obj subtype], kRealSubtype);
            NSString* numberA = [NSString stringWithFormat:@"%.6f", [obj realValue]];
            NSString* numberB = [NSString stringWithFormat:@"%.6f", 123.];
            XCTAssertEqualObjects(numberA, numberB);
        } else if (i == 4) {
            XCTAssertEqual([obj subtype], kRealSubtype);
            NSString* numberA = [NSString stringWithFormat:@"%.6f", [obj realValue]];
            NSString* numberB = [NSString stringWithFormat:@"%.6f", 3.14];
            NSString* numberC = [NSString stringWithFormat:@"%.6f", 0.123];
            XCTAssertEqualObjects(numberA, numberB);
            XCTAssertNotEqualObjects(numberA, numberC);
        }
    }
}

- (void)testGParserGObjectNextChar {
    GObject *o = [GObject create];
    char *b = "(I)";
    NSData *d = [NSData dataWithBytes:b length:strlen(b)];
    [o setRawContent:d];
    XCTAssertEqual([o peekNextChar], 'I');
    XCTAssertEqual([o nextChar], 'I');
    XCTAssertEqual([o nextChar], ')');
    XCTAssertEqual([o nextChar], ')');
}

- (void)testGParserParseLiteralStringsObject {
    GParser *p = [GParser parser];
    char *b = "(I am a literal string)";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    NSInteger i = 0;
    for (i = 0; i < [objs count]; i++) {
        GLiteralStringsObject *obj = [objs objectAtIndex:i];
        if (i == 0) {
            XCTAssertEqual([obj type], kLiteralStringsObject);
            XCTAssertEqualObjects([obj value], @"I am a literal string");
        }
    }
    
    // Test special characters escape
    b = "(A CR:\\r A LF:\\n A tab:\\t and a backspace:\\b "
        "A form feed:\\f "
        "A Left parenthesis:\\("
        "A right parenthesis:\\)"
        ")";
    char *test = "A CR:\r A LF:\n A tab:\t and a backspace:\b "
                 "A form feed:\f "
                 "A Left parenthesis:("
                 "A right parenthesis:)";
    d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    objs = [p objects];
    for (i = 0; i < [objs count]; i++) {
        GLiteralStringsObject *obj = [objs objectAtIndex:i];
        if (i == 0) {
            XCTAssertEqual([obj type], kLiteralStringsObject);
            XCTAssertEqualObjects([obj value], [NSString stringWithCString:test encoding:NSASCIIStringEncoding]);
        }
    }
    
    
    // Test "\\\r" "\\\r\n" "\\\n" characters escape
    b = "(These two strings\\\n"
        " are the same.\\\r\n"
        ")";
    test = "These two strings are the same.";
    d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    objs = [p objects];
    for (i = 0; i < [objs count]; i++) {
        GLiteralStringsObject *obj = [objs objectAtIndex:i];
        if (i == 0) {
            XCTAssertEqual([obj type], kLiteralStringsObject);
            XCTAssertEqualObjects([obj value], [NSString stringWithUTF8String:test]);
        }
    }
    
    // Test "\\40" "\\53" "\\053" characters escape
    b = "(\\40 \\53 \\053ABC)";
    test = "  + +ABC";
    d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    objs = [p objects];
    for (i = 0; i < [objs count]; i++) {
        GLiteralStringsObject *obj = [objs objectAtIndex:i];
        if (i == 0) {
            XCTAssertEqual([obj type], kLiteralStringsObject);
            XCTAssertEqualObjects([obj value], [NSString stringWithUTF8String:test]);
        }
    }
}
@end
