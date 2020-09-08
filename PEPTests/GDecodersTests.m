//
//  GDecodersTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 9/8/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GParser.h"
#import "GDecoders.h"

@interface GDecodersTests : XCTestCase

@end

@implementation GDecodersTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDecodeFlate {
    GParser *p = [GParser parser];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    // Even test_xref.pdf is in the `pdf` folder, we still only need to provide
    // file name in the path, no need to provide folder name
    NSString *path = [bundle pathForResource:@"test_xref" ofType:@"pdf"];
    NSData *d = [NSData dataWithContentsOfFile:path];
    [p setStream:d];
    
    NSDictionary *xref = [p parseXRef];
    
    // Page 1 content: 4 0 R
    GXRefEntry *x = [xref objectForKey:@"4-0"];
    unsigned int offset = [x offset];
    [[p lexer] setPos:offset];
    GIndirectObject* contentIndirect = (GIndirectObject*)[p parseNextObject];
    GStreamObject *stream = [contentIndirect object];
    NSData *content = [stream streamContent];
    NSData *decoded = decodeFlate(content);
    NSUInteger i;
    unsigned char * bytes = (unsigned char*)[decoded bytes];
    printf("\n");
    for (i = 0; i < [decoded length]; i++) {
        printf("%c", (unsigned char)(*(bytes+i)));
    }
    printf("\n");
}

@end
