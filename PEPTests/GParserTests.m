//
//  GLParserTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GParser.h"

@interface GParserTests : XCTestCase

@end

@implementation GParserTests

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

- (void)testGParserParseHexStringsObject {
    GParser *p = [GParser parser];
    char *b = "<4920616d20612068657820737472696e67>";
    char *test = "I am a hex string";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    NSData *d1 = [NSData dataWithBytes:test length:strlen(test)];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    NSInteger i = 0;
    for (i = 0; i < [objs count]; i++) {
        GHexStringsObject *obj = [objs objectAtIndex:i];
        if (i == 0) {
            XCTAssertEqual([obj type], kHexStringsObject);
            XCTAssertEqualObjects([obj value], d1);
        }
    }
}


- (void)testGParserParseNameObject {
    GParser *p = [GParser parser];
    char *b = "/Name1 /ASomewhatLongerName /A;Name_With-Various***Characters? /1.2 /$$ /@pattern /.notdef /Lime#20Green /paired#28#29parentheses /The_Key_of_F#23_Minor /A#42 /";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    NSInteger i = 0;
    for (i = 0; i < [objs count]; i++) {
        GNameObject *obj = [objs objectAtIndex:i];
        if (i == 0) {
            XCTAssertEqual([obj type], kNameObject);
            XCTAssertEqualObjects([obj value], @"Name1");
        } else if (i == 1){
            XCTAssertEqual([obj type], kNameObject);
            XCTAssertEqualObjects([obj value], @"ASomewhatLongerName");
        } else if (i == 2) {
            XCTAssertEqual([obj type], kNameObject);
            XCTAssertEqualObjects([obj value], @"A;Name_With-Various***Characters?");
        } else if (i == 3) {
            XCTAssertEqual([obj type], kNameObject);
            XCTAssertEqualObjects([obj value], @"1.2");
        } else if (i == 4) {
            XCTAssertEqual([obj type], kNameObject);
            XCTAssertEqualObjects([obj value], @"$$");
        } else if (i == 5) {
            XCTAssertEqual([obj type], kNameObject);
            XCTAssertEqualObjects([obj value], @"@pattern");
        } else if (i == 6) {
            XCTAssertEqual([obj type], kNameObject);
            XCTAssertEqualObjects([obj value], @".notdef");
        } else if (i == 7) {
            XCTAssertEqual([obj type], kNameObject);
            XCTAssertEqualObjects([obj value], @"Lime Green");
        } else if (i == 8) {
            XCTAssertEqual([obj type], kNameObject);
            XCTAssertEqualObjects([obj value], @"paired()parentheses");
        } else if (i == 9) {
            XCTAssertEqual([obj type], kNameObject);
            XCTAssertEqualObjects([obj value], @"The_Key_of_F#_Minor");
        } else if (i == 10) {
            XCTAssertEqual([obj type], kNameObject);
            XCTAssertEqualObjects([obj value], @"AB");
        } else if (i == 11) {
            XCTAssertEqual([obj type], kNameObject);
            XCTAssertEqualObjects([obj value], @"");
        }
    }
}

- (void)testGParserParseArrayObject {
    GParser *p = [GParser parser];
    char *b = "[549 3.14 false (Ralph) /SomeName [true 1024]]";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    NSInteger i = 0;
    for (i = 0; i < [objs count]; i++) {
        if (i == 0) {
            GArrayObject *array = [objs objectAtIndex:i];
            NSInteger j;
            for (j = 0; j < [[array value] count]; j++) {
                if (j == 0) {
                    GNumberObject *obj = [[array value] objectAtIndex:j];
                    XCTAssertEqual([obj type], kNumberObject);
                    XCTAssertEqual([obj subtype], kIntSubtype);
                    XCTAssertEqual([obj intValue], 549);
                } else if (j == 1) {
                    GNumberObject *obj = [[array value] objectAtIndex:j];
                    XCTAssertEqual([obj type], kNumberObject);
                    XCTAssertEqual([obj subtype], kRealSubtype);
                    NSString* numberA = [NSString stringWithFormat:@"%.6f", [obj realValue]];
                    NSString* numberB = [NSString stringWithFormat:@"%.6f", 3.14];
                    XCTAssertEqualObjects(numberA, numberB);
                } else if (j == 2) {
                    GBooleanObject *obj = [[array value] objectAtIndex:j];
                    XCTAssertEqual([obj type], kBooleanObject);
                    XCTAssertEqual([obj value], NO);
                } else if (j == 3) {
                    GLiteralStringsObject *obj = [[array value] objectAtIndex:j];
                    XCTAssertEqual([obj type], kLiteralStringsObject);
                    XCTAssertEqualObjects([obj value], @"Ralph");
                } else if (j == 4) {
                    GNameObject *obj = [[array value] objectAtIndex:j];
                    XCTAssertEqual([obj type], kNameObject);
                    XCTAssertEqualObjects([obj value], @"SomeName");
                } else if (j == 5) {
                    GArrayObject *subArray = [[array value] objectAtIndex:j];
                    NSInteger k;
                    for (k = 0; k < [[subArray value] count]; k++) {
                        if (k == 0) {
                            GBooleanObject *obj = [[subArray value] objectAtIndex:k];
                            XCTAssertEqual([obj type], kBooleanObject);
                            XCTAssertEqual([obj value], YES);
                        } else if (k == 1) {
                            GNumberObject *obj = [[subArray value] objectAtIndex:k];
                            XCTAssertEqual([obj type], kNumberObject);
                            XCTAssertEqual([obj subtype], kIntSubtype);
                            XCTAssertEqual([obj intValue], 1024);
                        }
                    }
                }
            }

        }
    }
}

- (void)testGParserParseDictionaryObject {
    GParser *p = [GParser parser];
    char *b = "<</Name (PEP) /Subtype /DictionaryExample /Length 128 "
              "/Subdictionary <<"
              "/Item1 4 "
              "/Item2 true "
              "/LastItem (not !) /VeryLastItem (OK) >>"
              ">>";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    NSInteger i = 0;
    for (i = 0; i < [objs count]; i++) {
        if (i == 0) {
            GDictionaryObject *obj = [objs objectAtIndex:i];
            NSMutableDictionary *dict = [obj value];
            for (id key in dict) {
                id v = [dict objectForKey:key];
                if ([key isEqualToString:@"Name"]) {
                    XCTAssertEqualObjects([(GLiteralStringsObject*)v value], @"PEP");
                } else if ([key isEqualToString:@"Subtype"]){
                    XCTAssertEqualObjects([(GNameObject*)v value], @"DictionaryExample");
                } else if ([key isEqualToString:@"Length"]) {
                    XCTAssertEqual([(GNumberObject*)v intValue], 128);
                } else if ([key isEqualToString:@"Subdictionary"]) {
                    XCTAssertTrue([v isKindOfClass: [GDictionaryObject class]]);
                    NSMutableDictionary *dict2 = [(GDictionaryObject*)v value];
                    for (id key2 in dict2) {
                        id v2 = [dict2 objectForKey:key2];
                        if ([key2 isEqualToString:@"Item1"]) {
                            XCTAssertEqual([(GNumberObject*)v2 intValue], 4);
                        } else if ([key2 isEqualToString:@"Item2"]) {
                            XCTAssertEqual([(GBooleanObject*)v2 value], YES);
                        } else if ([key2 isEqualToString:@"LastItem"]) {
                            XCTAssertEqualObjects([(GLiteralStringsObject*)v2 value], @"not !");
                        } else if ([key2 isEqualToString:@"VeryLastItem"]) {
                            XCTAssertEqualObjects([(GLiteralStringsObject*)v2 value], @"OK");
                        }
                    }
                }
            }
        }
    }
    
}
@end
