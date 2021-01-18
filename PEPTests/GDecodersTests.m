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
#import "GMisc.h"

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
    [p updateXRefDictionary];
    
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

- (void)testDecodeASCII85 {
    char *s = "9jqo^BlbD-BleB1DJ+*+F(f,q/0JhKF<GL>Cj@.4Gp$d7F!,L7@<6@)/0JDEF<G%<+EV:2F!,O<DJ+*.@<*K0@<6L(Df-\\0Ec5e;DffZ(EZee.Bl.9pF\"AGXBPCsi+DGm>@3BB/F*&OCAfu2/AKYi(DIb:@FD,*)+C]U=@3BN#EcYf8ATD3s@q?d$AftVqCh[NqF<G:8+EV:.+Cf>-FD5W8ARlolDIal(DId<j@<?3r@:F%a+D58'ATD4$Bl@l3De:,-DJs`8ARoFb/0JMK@qB4^F!,R<AKZ&-DfTqBG%G>uD.RTpAKYo'+CT/5+Cei#DII?(E,9)oF*2M7/cYkO~>";
    NSData *data = [NSData dataWithBytes:s length:strlen(s)];
    NSData *result = decodeASCII85(data);
    char *assertString = "Man is distinguished, not only by his reason, but by this singular passion from other animals, which is a lust of the mind, that by a perseverance of delight in the continued and indefatigable generation of knowledge, exceeds the short vehemence of any carnal pleasure.";
    NSData *assertData = [NSData dataWithBytes:assertString length:strlen(assertString)];
    XCTAssertEqualObjects(result, assertData);
}
@end
