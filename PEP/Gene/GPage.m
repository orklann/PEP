//
//  GPage.m
//  PEP
//
//  Created by Aaron Elkins on 9/17/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GPage.h"
#import "GDecoders.h"

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

- (void)parsePageContent {
    GRefObject *ref = [[pageDictionary value] objectForKey:@"Contents"];
    NSString *refString = [NSString stringWithFormat:@"%d-%d",
                           [ref objectNumber],
                           [ref generationNumber]];
    GIndirectObject *contentStreamIndirect = [parser getObjectByRef:refString];
    GStreamObject *contentStream = [contentStreamIndirect object];
    NSData *data = [contentStream streamContent];
    pageContent = decodeFlate(data);
    
    NSUInteger i;
    unsigned char * bytes = (unsigned char*)[pageContent bytes];
    for (i = 0; i < [pageContent length]; i++) {
        printf("%c", (unsigned char)(*(bytes+i)));
    }
    printf("\n");
}
@end
