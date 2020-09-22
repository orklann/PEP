//
//  GPage.m
//  PEP
//
//  Created by Aaron Elkins on 9/17/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GPage.h"
#import "GDecoders.h"
#import "GMisc.h"
#import "GInterpreter.h"

@implementation GPage

+ (id)create {
    GPage *p = [[GPage alloc] init];
    return p;
}

- (void)setPageDictionary:(GDictionaryObject*)d {
    pageDictionary = d;
}

- (GDictionaryObject*)pageDictionary {
    return pageDictionary;
}

- (void)setParser:(GParser*)p {
    parser = p;
}

- (void)setDocument:(GDocument*)d {
    doc = d;
}

- (void)parsePageContent {
    // Contents can be a GArrayObject instead of GRefObject,
    // TODO: Handle this case later.
    GRefObject *ref = [[pageDictionary value] objectForKey:@"Contents"];
    NSString *refString = [NSString stringWithFormat:@"%d-%d",
                           [ref objectNumber],
                           [ref generationNumber]];
    GStreamObject *contentStream = [parser getObjectByRef:refString];
    pageContent = [contentStream getDecodedStreamContent];
    
    printData(pageContent);
}

- (void)render:(CGContextRef)context {
    GInterpreter *interpreter = [GInterpreter create];
    [interpreter setParser:parser];
    [interpreter setInput:pageContent];
    [interpreter eval:context];
}
@end
