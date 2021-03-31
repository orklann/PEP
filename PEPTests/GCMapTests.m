//
//  GCMapTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 3/31/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GCMap.h"

@interface GCMapTests : XCTestCase

@end

@implementation GCMapTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test1 {
    char *b = "/CIDInit /ProcSet findresource begin\n"
              "12 dict begin\n"
              "begincmap\n"
              "/CMapType 2 def\n"
              "/CMapName/R154 def\n"
              "1 begincodespacerange\n"
              "<00><ff>\n"
              "endcodespacerange\n"
              "2 beginbfrange\n"
              "<0f><0f><2022>\n"
              "<1c><1c><226a>\n"
              "endbfrange\n"
              "endcmap\n"
              "CMapName currentdict /CMap defineresource pop\n"
              "end end\n";
    
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    GCMap *map = [GCMap create];
    [map eval:d];
    for (NSNumber *key in [[map unicodeMaps] allKeys]) {
        NSString *s = [[map unicodeMaps] objectForKey:key];
        if ([key intValue] == 0x0f) {
            XCTAssertEqualObjects(s, @"•");
        } else if ([key intValue] == 0x1c) {
            XCTAssertEqualObjects(s, @"≪");
        }
    }
}

- (void)test2 {
    char *b = "/CIDInit /ProcSet findresource begin\n"
              "12 dict begin\n"
              "begincmap\n"
              "/CIDSystemInfo\n"
              "<</Registry (Adobe)\n"
              "/Ordering (UCS2)\n"
              "/Supplement 0\n"
              ">> def\n"
              "/CMapName /Adobe-Identity-UCS2 def\n"
              "/CMapType 2 def\n"
              "1 begincodespacerange\n"
              "<0000> <FFFF>\n"
              "endcodespacerange\n"
              "2 beginbfrange\n"
              "<0000> <005E> <0020>\n"
              "<005F> <0061> [<00660066> <00660069> <00660066006C>]\n"
              "endbfrange\n"
              "1 beginbfchar\n"
              "<3A51> <D840DC3E>\n"
              "endbfchar\n"
              "endcmap\n"
              "CMapName currentdict /CMap defineresource pop\n"
              "end\n"
              "end\n"
              "endstream\n"
              "endobj\n";
    
    NSData *d = [NSData dataWithBytes:b length:strlen(b) + 1];
    GCMap *map = [GCMap create];
    [map eval:d];
    for (NSNumber *key in [[map unicodeMaps] allKeys]) {
        NSString *s = [[map unicodeMaps] objectForKey:key];
        if ([key intValue] == 0x5e) {
            XCTAssertEqualObjects(s, @" ");
        } else if ([key intValue] == 0x5f) {
            XCTAssertEqualObjects(s, @"ff");
        } else if ([key intValue] == 0x60) {
            XCTAssertEqualObjects(s, @"fi");
        } else if ([key intValue] == 0x61) {
            XCTAssertEqualObjects(s, @"ffl");
        } else if ([key intValue] == 0x3a51) {
            XCTAssertEqualObjects(s, @"𠀾"); // Test: <3A51> <D840DC3E>
        }
    }
}
@end
