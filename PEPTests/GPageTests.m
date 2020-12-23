//
//  GPageTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 10/22/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GPage.h"
#import "GBinaryData.h"

@interface GPageTests : XCTestCase

@end

@implementation GPageTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testBuildNewXRefTable1 {
    GPage *p = [GPage create];
    GBinaryData *b = [GBinaryData create];
    [b setObjectNumber:2];
    [b setGenerationNumber:0];
    [b setOffset:20];
    [p.dataToUpdate addObject:b];
    
    b = [GBinaryData create];
    [b setObjectNumber:1];
    [b setGenerationNumber:0];
    [b setOffset:10];
    [p.dataToUpdate addObject:b];
    
    b = [GBinaryData create];
    [b setObjectNumber:4];
    [b setGenerationNumber:0];
    [b setOffset:30];
    [p.dataToUpdate addObject:b];
    
    NSData *data = [p buildNewXRefTable];
    NSString *s = @"xref\r\n"
                   "1 2\r\n"
                   "0000000010 00000 n\r\n"
                   "0000000020 00000 n\r\n"
                   "4 1\r\n"
                   "0000000030 00000 n\r\n";
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    XCTAssertEqualObjects(ret, s);
}

- (void)testBuildNewXRefTable2 {
    GPage *p = [GPage create];
    GBinaryData *b = [GBinaryData create];
    [b setObjectNumber:2];
    [b setGenerationNumber:0];
    [b setOffset:20];
    [p.dataToUpdate addObject:b];
    
    b = [GBinaryData create];
    [b setObjectNumber:1];
    [b setGenerationNumber:0];
    [b setOffset:10];
    [p.dataToUpdate addObject:b];
    
    NSData *data = [p buildNewXRefTable];
    NSString *s = @"xref\r\n"
                   "1 2\r\n"
                   "0000000010 00000 n\r\n"
                   "0000000020 00000 n\r\n";
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    XCTAssertEqualObjects(ret, s);
}

- (void)testBuildNewXRefTable3 {
    GPage *p = [GPage create];
    GBinaryData *b = [GBinaryData create];
    [b setObjectNumber:2];
    [b setGenerationNumber:0];
    [b setOffset:20];
    [p.dataToUpdate addObject:b];
    
    b = [GBinaryData create];
    [b setObjectNumber:1];
    [b setGenerationNumber:0];
    [b setOffset:10];
    [p.dataToUpdate addObject:b];
    
    b = [GBinaryData create];
    [b setObjectNumber:4];
    [b setGenerationNumber:0];
    [b setOffset:30];
    [p.dataToUpdate addObject:b];
    
    b = [GBinaryData create];
    [b setObjectNumber:5];
    [b setGenerationNumber:0];
    [b setOffset:40];
    [p.dataToUpdate addObject:b];
    
    NSData *data = [p buildNewXRefTable];
    NSString *s = @"xref\r\n"
                   "1 2\r\n"
                   "0000000010 00000 n\r\n"
                   "0000000020 00000 n\r\n"
                   "4 2\r\n"
                   "0000000030 00000 n\r\n"
                   "0000000040 00000 n\r\n";
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    XCTAssertEqualObjects(ret, s);
}


@end
