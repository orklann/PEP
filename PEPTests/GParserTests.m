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
        " are\\\r the same.\\\r\n"
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

- (void)testGParserParseStreamObject {
    GParser *p = [GParser parser];
    char *b = "<</Length 4 >>stream\n"
              "q\n"
              "Q\n"
              "\n"
              "endstream";
    char *test = "q\nQ\n";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    NSData *d2 = [NSData dataWithBytes:test length:strlen(test)];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    NSInteger i = 0;
    for (i = 0; i < [objs count]; i++) {
        if (i == 0) {
            GStreamObject *obj = [objs objectAtIndex:i];
            XCTAssertEqual([obj type], kStreamObject);
            GDictionaryObject *dict = [obj dictionaryObject];
            for (id key in [dict value]) {
                if ([key isEqualToString:@"Length"]) {
                    GNumberObject *v = [[dict value] objectForKey:key];
                    XCTAssertEqual([v intValue], 4);
                }
            }
            XCTAssertEqualObjects([obj streamContent], d2);
        }
    }
}

- (void)testGParserParseIndirectmObject {
    GParser *p = [GParser parser];
    char *b = "10 0 obj\n"
              "<</Length 4 >>stream\n"
              "q\n"
              "Q\n"
              "\n"
              "endstream"
              "\n"
              "endobj"
              "\n 10";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    char *test = "q\nQ\n";
    NSData *d2 = [NSData dataWithBytes:test length:strlen(test)];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    NSInteger i = 0;
    for (i = 0; i < [objs count]; i++) {
        if (i == 0) {
            GIndirectObject *obj = [objs objectAtIndex:i];
            XCTAssertEqual([obj objectNumber], 10);
            XCTAssertEqual([obj generationNumber], 0);
            GStreamObject* contentObject = (GStreamObject*)[obj object];
            for (id key in [[contentObject dictionaryObject] value]) {
                if ([key isEqualToString:@"Name"]) {
                    GLiteralStringsObject *s = [[[contentObject dictionaryObject] value] objectForKey:key];
                    XCTAssertEqualObjects([s value], @"PEP");
                } else if ([key isEqualToString:@"Length"]) {
                    GNumberObject *n = [[[contentObject dictionaryObject] value] objectForKey:key];
                    XCTAssertEqual([n intValue], 4);
                    XCTAssertNotEqual([n intValue], 0);
                }
            }
            XCTAssertEqualObjects([contentObject streamContent], d2);
        }
    }
}

- (void)testGParserReturnAnyObject {
    GParser *p = [GParser parser];
    char *b = "10 0 obj\n"
              "<</Name (PEP) /Length 128>>"
              "\n"
              "endobj";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    
    NSInteger i = 0;
    for (i = 0; i < [objs count]; i++) {
        id obj = [objs objectAtIndex:0];
        XCTAssertEqual([(GObject*)obj type], kIndirectObject);
        XCTAssertEqual([(GIndirectObject*)obj objectNumber], 10);
    }
}

- (void)testGParserNullObject {
    GParser *p = [GParser parser];
    char *b = "null";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    
    NSInteger i = 0;
    for (i = 0; i < [objs count]; i++) {
        id obj = [objs objectAtIndex:0];
        XCTAssertEqual([(GObject*)obj type], kNullObject);
    }
}

- (void)testGParserRefObject {
    GParser *p = [GParser parser];
    char *b = "10 0 R 2 0 R";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    
    NSInteger i = 0;
    for (i = 0; i < [objs count]; i++) {
        GRefObject *obj = [objs objectAtIndex:0];
        XCTAssertEqual([obj type], kRefObject);
        XCTAssertEqual([obj objectNumber], 10);
        XCTAssertEqual([obj generationNumber], 0);
    }
}

- (void)testGParserNextObject {
    GParser *p = [GParser parser];
    char *b = "null false true 1 2 3 10 0 R \n"
              " 1 2 3 \n"
              "(Hello World) \n"
              "<4920616d20612068657820737472696e67> \n"
              "/Name \n"
              "[1 2] \n"
              "<</Name (PEP)>> \n"
              "<</Type /Font /Length 18 >>\n"
              "stream\n"
              "(This is a stream)\n"
              "endstream";
    
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    id o;
    o = [p parseNextObject];
    XCTAssertEqual([(GNullObject*)o type], kNullObject);
    
    o = [p parseNextObject];
    XCTAssertEqual([(GBooleanObject*)o type], kBooleanObject);
    XCTAssertEqual([(GBooleanObject*)o value], NO);
    
    o = [p parseNextObject];
    XCTAssertEqual([(GBooleanObject*)o type], kBooleanObject);
    XCTAssertEqual([(GBooleanObject*)o value], YES);
    
    // 1
    o = [p parseNextObject];
    XCTAssertEqual([(GNumberObject*)o type], kNumberObject);
    XCTAssertEqual([(GNumberObject*)o intValue], 1);
    
    // 2
    o = [p parseNextObject];
    XCTAssertEqual([(GNumberObject*)o type], kNumberObject);
    XCTAssertEqual([(GNumberObject*)o intValue], 2);
    
    // 3
    o = [p parseNextObject];
    XCTAssertEqual([(GNumberObject*)o type], kNumberObject);
    XCTAssertEqual([(GNumberObject*)o intValue], 3);
    
    // 10 0 R
    o = [p parseNextObject];
    XCTAssertEqual([(GRefObject*)o type], kRefObject);
    XCTAssertEqual([(GRefObject*)o objectNumber], 10);
    XCTAssertEqual([(GRefObject*)o generationNumber], 0);
    
    // 1
    o = [p parseNextObject];
    XCTAssertEqual([(GNumberObject*)o type], kNumberObject);
    XCTAssertEqual([(GNumberObject*)o intValue], 1);
    
    // 2
    o = [p parseNextObject];
    XCTAssertEqual([(GNumberObject*)o type], kNumberObject);
    XCTAssertEqual([(GNumberObject*)o intValue], 2);
    
    // 3
    o = [p parseNextObject];
    XCTAssertEqual([(GNumberObject*)o type], kNumberObject);
    XCTAssertEqual([(GNumberObject*)o intValue], 3);
    
    // (Hello World)
    o = [p parseNextObject];
    XCTAssertEqual([(GLiteralStringsObject*)o type], kLiteralStringsObject);
    XCTAssertEqualObjects([(GLiteralStringsObject*)o value],
                   [NSString stringWithUTF8String:"Hello World"]);
    
    // <4920616d20612068657820737472696e67>;
    char *test = "I am a hex string";
    NSData *d1 = [NSData dataWithBytes:test length:strlen(test)];
    o = [p parseNextObject];
    XCTAssertEqual([(GHexStringsObject*)o type], kHexStringsObject);
    XCTAssertEqualObjects([(GHexStringsObject*)o value],
                   d1);
    
    // /Name
    o = [p parseNextObject];
    XCTAssertEqual([(GNameObject*)o type], kNameObject);
    XCTAssertEqualObjects([(GNameObject*)o value],
                   [NSString stringWithUTF8String:"Name"]);
    
    // [1 2]
    o = [p parseNextObject];
    XCTAssertEqual([(GArrayObject*)o type], kArrayObject);
    
    // <</Name (PEP)>>, just test it's type
    o = [p parseNextObject];
    XCTAssertEqual([(GDictionaryObject*)o type], kDictionaryObject);
    
    // <</Type /Font /Length 18 >>
    // stream
    // (This is a stream)
    // endstream
    o = [p parseNextObject];
    XCTAssertEqual([(GStreamObject*)o type], kStreamObject);
    
    o = [p parseNextObject];
    XCTAssertEqual([(GEndObject*)o type], kEndObject);
}

- (void)testGParserGetStartXRef {
    GParser *p = [GParser parser];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    // Even test_xref.pdf is in the `pdf` folder, we still only need to provide
    // file name in the path, no need to provide folder name
    NSString *path = [bundle pathForResource:@"test_xref" ofType:@"pdf"];
    NSData *d = [NSData dataWithContentsOfFile:path];
    [p setStream:d];
    
    unsigned int startXRef = [p getStartXRef];
    XCTAssertEqual(startXRef, 16108);
}

- (void)testGParserParseXRef {
    GParser *p = [GParser parser];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    // Even test_xref.pdf is in the `pdf` folder, we still only need to provide
    // file name in the path, no need to provide folder name
    NSString *path = [bundle pathForResource:@"PEP_incremental" ofType:@"pdf"];
    NSData *d = [NSData dataWithContentsOfFile:path];
    [p setStream:d];
    
    NSMutableDictionary *dict = [p parseXRef];
    
    // Test latest XRef
    for (id key in dict) {
        if ([key isEqualTo:@"1-0"]) {     // Test first xref entry (object number is 1)
            GXRefEntry *x = [dict objectForKey:key];
            XCTAssertEqual([x objectNumber], 1);
            XCTAssertEqual([x offset], 44968);
            XCTAssertEqual([x generationNumber], 0);
            XCTAssertEqual([x inUse], 'n');
        } else if ([key isEqualTo:@"38-0"]) { // Test 24 xref entry (object number is 24)
            GXRefEntry *x = [dict objectForKey:key];
            XCTAssertEqual([x objectNumber], 38);
            XCTAssertEqual([x offset], 34371);
            XCTAssertEqual([x generationNumber], 0);
            XCTAssertEqual([x inUse], 'n');
        }
    }
    
    // Test previous XRef
    NSMutableDictionary *prev = [dict objectForKey:@"PrevXRef"];
    for (id key in prev) {
        // Test first xref entry (object number is 1)
        if ([key isEqualTo:@"1-0"]) {
            GXRefEntry *x = [prev objectForKey:key];
            XCTAssertEqual([x objectNumber], 1);
            XCTAssertEqual([x offset], 33784);
            XCTAssertEqual([x generationNumber], 0);
            XCTAssertEqual([x inUse], 'n');
        } else if ([key isEqualTo:@"31-0"]) {
            GXRefEntry *x = [prev objectForKey:key];
            XCTAssertEqual([x objectNumber], 31);
            XCTAssertEqual([x offset], 25638);
            XCTAssertEqual([x generationNumber], 0);
            XCTAssertEqual([x inUse], 'n');
        }
    }
}

- (void)testGParserWithPDF {
    GParser *p = [GParser parser];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    // Even test_xref.pdf is in the `pdf` folder, we still only need to provide
    // file name in the path, no need to provide folder name
    NSString *path = [bundle pathForResource:@"test_xref" ofType:@"pdf"];
    NSData *d = [NSData dataWithContentsOfFile:path];
    [p setStream:d];
    
    NSDictionary *dict = [p parseXRef];
    
    // Test `23 0 obj`: GIndirectObject -> GNumberObject
    GXRefEntry *x = [dict objectForKey:@"23-0"];
    unsigned int offset = [x offset];
    [[p lexer] setPos:offset];
    id o = [p parseNextObject];
    XCTAssertEqual([(GObject*)o type], kIndirectObject);
    GNumberObject *object = (GNumberObject*)[(GIndirectObject *)o object];
    XCTAssertEqual([object subtype], kIntSubtype);
    XCTAssertEqual([object intValue], 2862);
    
    // Test `11 0 obj`: GIndirectObject -> GDictionaryObject
    x = [dict objectForKey:@"11-0"];
    offset = [x offset];
    [[p lexer] setPos:offset];
    o = [p parseNextObject];
    XCTAssertEqual([(GObject*)o type], kIndirectObject);
    GDictionaryObject *obj2 = (GDictionaryObject*)[(GIndirectObject *)o object];
    XCTAssertEqual([obj2 type], kDictionaryObject);
    NSDictionary *dict2 = [obj2 value];
    // /Type /ExtGState
    GNameObject *state = [dict2 objectForKey:@"Type"];
    XCTAssertEqualObjects([state value], @"ExtGState");
    // /AAPL:AA false
    GBooleanObject *boolean = [dict2 objectForKey:@"AAPL:AA"];
    XCTAssertEqual([boolean value], NO);
    
    // Test `8 0 obj`: GIndirectObject -> GArrayObject
    x = [dict objectForKey:@"8-0"];
    offset = [x offset];
    [[p lexer] setPos:offset];
    o = [p parseNextObject];
    XCTAssertEqual([(GObject*)o type], kIndirectObject);
    GArrayObject *a = (GArrayObject*)[(GIndirectObject *)o object];
    XCTAssertEqual([a type], kArrayObject);
    GNameObject *a1 = [[a value] objectAtIndex:0];
    XCTAssertEqualObjects([a1 value], @"ICCBased");
    GIndirectObject *i1 = [[a value] objectAtIndex:1];
    XCTAssertEqual([i1 objectNumber], 13);
    XCTAssertEqual([i1 generationNumber], 0);
    
    // Test `15 0 obj`: GIndirectObject -> GStreamObject
    x = [dict objectForKey:@"15-0"];
    offset = [x offset];
    [[p lexer] setPos:offset];
    o = [p parseNextObject];
    XCTAssertEqual([(GObject*)o type], kIndirectObject);
    GStreamObject *s = (GStreamObject*)[(GIndirectObject *)o object];
    XCTAssertEqual([s type], kStreamObject);
    // `/Length`
    GIndirectObject *i2 = [[[s dictionaryObject] value] objectForKey:@"Length"];
    XCTAssertEqual([i2 objectNumber], 16);
    XCTAssertEqual([i2 generationNumber], 0);
    // `/N`
    GNumberObject *n = [[[s dictionaryObject] value] objectForKey:@"N"];
    XCTAssertEqual([n intValue], 3);
}

- (void)testGParserGetTrailer {
    GParser *p = [GParser parser];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    // Even test_xref.pdf is in the `pdf` folder, we still only need to provide
    // file name in the path, no need to provide folder name
    NSString *path = [bundle pathForResource:@"test_xref" ofType:@"pdf"];
    NSData *d = [NSData dataWithContentsOfFile:path];
    [p setStream:d];
    
    GDictionaryObject *trailer = [p getTrailer];
    XCTAssertEqual([trailer type], kDictionaryObject);
    NSDictionary *dict = [trailer value];
    // Test `/Size 24`
    GNumberObject *size = [dict objectForKey:@"Size"];
    XCTAssertEqual([size intValue], 24);
    
    // Test `/Root 17 0 R`
    GRefObject *root = [dict objectForKey:@"Root"];
    XCTAssertEqual([root objectNumber], 17);
    XCTAssertEqual([root generationNumber], 0);
}

- (void)testGParserNextObjectCommandObject {
    GParser *p = [GParser parser];
    char *b = "0.9790795 0 0 -0.9790795 72 720 cm";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    id o;
    NSMutableArray *objs = [NSMutableArray array];
    // Add 6 number objects
    NSUInteger i;
    for (i = 0; i < 6; i++) {
        o = [p parseNextObject];
        [objs addObject:o];
    }

    o = [p parseNextObject];
    XCTAssertEqual([(GCommandObject*)o type], kCommandObject);
    XCTAssertEqualObjects([(GCommandObject*)o cmd], @"cm");
    
    NSArray *args = getCommandArgs(objs, 6);
    GNumberObject *firstArg = [args firstObject];
    NSString* numberA = [NSString stringWithFormat:@"%.7f", [firstArg realValue]];
    NSString* numberB = [NSString stringWithFormat:@"%.7f", 0.9790795];
    XCTAssertEqualObjects(numberA, numberB);
    
    GNumberObject *lastArg = [args lastObject];
    XCTAssertEqual([lastArg type], kNumberObject);
    XCTAssertEqual([lastArg intValue], 720);
}
@end
