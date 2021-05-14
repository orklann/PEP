//
//  GCompilerTests.m
//  PEPTests
//
//  Created by Aaron Elkins on 5/14/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GCompiler.h"
#import "GOperators.h"
#import "GGlyph.h"
#import "GPage.h"

@interface GCompilerTests : XCTestCase

@end

@implementation GCompilerTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGCompiler1 {
    NSMutableArray *ma = [NSMutableArray array];
    [ma addObject:[GcsOperator create]];
    [ma addObject:[GcsOperator create]];
    [ma addObject:[GGlyph create]];
    [ma addObject:[GGlyph create]];
    
    GPage *page = [GPage create];
    
    GCompiler *comp = [GCompiler compilerWithPage:page];
    NSArray *result = [comp buildGlyphsGroupArray:ma];
    
    XCTAssertEqualObjects([[result firstObject] className], @"GcsOperator");
    XCTAssertEqual([[result objectAtIndex:2] count], 2);
    XCTAssertEqualObjects([[[result objectAtIndex:2] firstObject] className], @"GGlyph");
}

- (void)testGCompiler2 {
    NSMutableArray *ma = [NSMutableArray array];
    [ma addObject:[GcsOperator create]];
    [ma addObject:[GcsOperator create]];
    [ma addObject:[GGlyph create]];
    [ma addObject:[GGlyph create]];
    [ma addObject:[GcsOperator create]];
    
    GPage *page = [GPage create];
    
    GCompiler *comp = [GCompiler compilerWithPage:page];
    NSArray *result = [comp buildGlyphsGroupArray:ma];
    
    XCTAssertEqualObjects([[result firstObject] className], @"GcsOperator");
    XCTAssertEqual([[result objectAtIndex:2] count], 2);
    XCTAssertEqualObjects([[[result objectAtIndex:2] firstObject] className], @"GGlyph");
    XCTAssertEqualObjects([[result lastObject] className], @"GcsOperator");
}

- (void)testGCompiler3 {
    NSMutableArray *ma = [NSMutableArray array];
    [ma addObject:[GcsOperator create]];
    [ma addObject:[GcsOperator create]];
    [ma addObject:[GGlyph create]];
    [ma addObject:[GGlyph create]];
    [ma addObject:[GcsOperator create]];
    [ma addObject:[GGlyph create]];
    [ma addObject:[GGlyph create]];
    
    GPage *page = [GPage create];
    
    GCompiler *comp = [GCompiler compilerWithPage:page];
    NSArray *result = [comp buildGlyphsGroupArray:ma];
    
    XCTAssertEqualObjects([[result firstObject] className], @"GcsOperator");
    XCTAssertEqual([[result objectAtIndex:4] count], 2);
    XCTAssertEqualObjects([[[result objectAtIndex:4] firstObject] className], @"GGlyph");
}

- (void)testGCompiler4 {
    NSMutableArray *ma = [NSMutableArray array];
    [ma addObject:[GcsOperator create]];
    [ma addObject:[GcsOperator create]];
    [ma addObject:[GGlyph create]];
    [ma addObject:[GGlyph create]];
    [ma addObject:[GcsOperator create]];
    [ma addObject:[GGlyph create]];
    [ma addObject:[GGlyph create]];
    [ma addObject:[GcsOperator create]];
    
    GPage *page = [GPage create];
    
    GCompiler *comp = [GCompiler compilerWithPage:page];
    NSArray *result = [comp buildGlyphsGroupArray:ma];
    
    XCTAssertEqualObjects([[result firstObject] className], @"GcsOperator");
    XCTAssertEqual([[result objectAtIndex:4] count], 2);
    XCTAssertEqualObjects([[[result objectAtIndex:4] firstObject] className], @"GGlyph");
    XCTAssertEqualObjects([[result lastObject] className], @"GcsOperator");
}
@end
