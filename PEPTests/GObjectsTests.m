//
//  GObjectsTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 10/22/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GParser.h"
#import "GObjects.h"

@interface GObjectsTests : XCTestCase

@end

@implementation GObjectsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGBooleanObjectToString {
    GParser *p = [GParser parser];
    char *b = "false true";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    
    GBooleanObject *f = [objs firstObject];
    XCTAssertEqualObjects([f toString], @"false");
    
    GBooleanObject *t = [objs lastObject];
    XCTAssertEqualObjects([t toString], @"true");
}

- (void)testGNumberObjectToString {
    GParser *p = [GParser parser];
    char *b = "1 3.1415";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    
    GNumberObject *first = [objs firstObject];
    XCTAssertEqualObjects([first toString], @"1");
    
    GNumberObject *second = [objs lastObject];
    XCTAssertEqualObjects([second toString], @"3.141500");
}

- (void)testGLiteralStringsObjectToString {
    GParser *p = [GParser parser];
    char *b = "(I am a literal string)";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    
    GLiteralStringsObject *first = [objs firstObject];
    XCTAssertEqualObjects([first toString], @"(I am a literal string)");
}

- (void)testGHexStringsObjectToString {
    GParser *p = [GParser parser];
    char *b = "<4920616d20612068657820737472696e67>";
    NSString *test = @"<4920616d20612068657820737472696e67>";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    GHexStringsObject *first = [objs firstObject];
    XCTAssertEqualObjects([first toString], test);
    
    // Test rawString
    p = [GParser parser];
    char *b2 = "<3A51> <D840DC3E>";
    NSString *test1 = @"3A51";
    NSString *test2 = @"D840DC3E";
    d = [NSData dataWithBytes:b2 length:strlen(b2) + 1];
    [p setStream:d];
    [p parse];
    objs = [p objects];
    first = [objs firstObject];
    XCTAssertEqualObjects([first rawString], test1);
    GHexStringsObject *last = [objs lastObject];
    XCTAssertEqualObjects([last rawString], test2);
    
    // Test intValue
    XCTAssertEqual([first integerValue], 0x3A51);
    XCTAssertEqual([last integerValue], 0xD840DC3E);
}

- (void)testGNameObjectToString {
    GParser *p = [GParser parser];
    char *b = "/Name1 /A;Name_With-Various***Characters?  /Lime#20Green /";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    
    GNumberObject *n1 = [objs firstObject];
    XCTAssertEqualObjects([n1 toString], @"/Name1");
    
    GNumberObject *n2 = [objs objectAtIndex:1];
    XCTAssertEqualObjects([n2 toString], @"/A;Name_With-Various***Characters?");
    
    GNumberObject *n3 = [objs objectAtIndex:2];
    XCTAssertEqualObjects([n3 toString], @"/Lime#20Green");
    
    GNumberObject *n4 = [objs objectAtIndex:3];
    XCTAssertEqualObjects([n4 toString], @"/");

}

- (void)testGNullObjectToString {
    GParser *p = [GParser parser];
    char *b = "null";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    
    GNullObject *first = [objs firstObject];
    XCTAssertEqualObjects([first toString], @"null");
}

- (void)testGRefObjectToString {
    GParser *p = [GParser parser];
    char *b = "1 0 R";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    
    GRefObject *first = [objs firstObject];
    XCTAssertEqualObjects([first toString], @"1 0 R");
}

- (void)testGArrayObjectToString {
    GParser *p = [GParser parser];
    char *b = "[1 0 R 549 3.14 false (Ralph) /SomeName [true 1024] null <4920616d20612068657820737472696e67>]";
    NSString *test = [NSString stringWithUTF8String:"[1 0 R 549 3.140000 false (Ralph) /SomeName [true 1024] null <4920616d20612068657820737472696e67>]"];
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    
    GArrayObject *first = [objs firstObject];
    XCTAssertEqualObjects([first toString], test);
}

- (void)testGDictionaryObjectToString {
    GParser *p = [GParser parser];
    char *b = "<</Name (PEP) /Subtype /DictionaryExample /Length 128 "
            "/Subdictionary <<"
            "/Item1 4 "
            "/Item2 true "
            "/LastItem (not !) /VeryLastItem (OK)>>"
            ">>";
    
    // Hard coded this test string for keys orders in NSDictionary
    NSString *test = @"<</Subtype /DictionaryExample /Name (PEP) /Subdictionary <</Item2 true /Item1 4 /LastItem (not !) /VeryLastItem (OK)>> /Length 128>>";
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    [p setStream:d];
    [p parse];
    NSMutableArray *objs = [p objects];
    
    GArrayObject *first = [objs firstObject];
    XCTAssertEqualObjects([first toString], test);
}
@end
