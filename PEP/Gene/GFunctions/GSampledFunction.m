//
//  GSampledFunction.m
//  PEP
//
//  Created by Aaron Elkins on 4/28/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GSampledFunction.h"
#import "GObjects.h"

@implementation GSampledFunction

+ (id)functionWithStreamObject:(GStreamObject*)streamObj {
    GSampledFunction *obj = [[GSampledFunction alloc] init];
    [obj setStreamObject:streamObj];
    [obj parse];
    return obj;
}

- (void)setStreamObject:(GStreamObject*)so {
    streamObj = so;
}

- (void)parse {
    GDictionaryObject *dict = [streamObj dictionaryObject];
    
    // Domain & input size
    GArrayObject *domainArray = [[dict value] objectForKey:@"Domain"];
    NSArray *domain_origin = [domainArray value];
    _inputSize = (int)([domain_origin count] / 2);
    _domain = [self toMultiArray:domain_origin];
    
    // Range & output size
    GArrayObject *rangeArray = [[dict value] objectForKey:@"Range"];
    NSArray *range_origin = [rangeArray value];
    _outputSize = (int)([range_origin count] / 2);
    _range = [self toMultiArray:range_origin];
    
    // Size
    GArrayObject *sizeArray = [[dict value] objectForKey:@"Size"];
    _size = [sizeArray value];
    
    // Bits Per Sample: bps
    GNumberObject *bpsObject = [[dict value] objectForKey:@"BitsPerSample"];
    _bps = [bpsObject intValue];
    
    // Encode
    GArrayObject *encodeArray = [[dict value] objectForKey:@"Encode"];
    if (encodeArray == nil) {
        NSMutableArray *tmp = [NSMutableArray array];
        for (int i = 0; i < _inputSize; ++i) {
            GNumberObject *n1 = [GNumberObject create];
            [n1 setIntValue:0];
            GNumberObject *n2 = [_size objectAtIndex:i];
            NSArray *a = [NSArray arrayWithObjects:n1, n2, nil];
            [tmp addObject:a];
        }
        _encode = [NSArray arrayWithArray:tmp];
    } else {
        _encode = [self toMultiArray:[encodeArray value]];
    }
    
    // Decode
    GArrayObject *decodeArray = [[dict value] objectForKey:@"Decode"];
    if (decodeArray == nil) {
        _decode = _range;
    } else {
        _decode = [self toMultiArray:[decodeArray value]];
    }
    
    // TODO: Get samples
}

- (NSArray*)toMultiArray:(NSArray *)array {
    NSMutableArray *result = [NSMutableArray array];
    for (int i = 0; i < [array count]; i += 2) {
        GNumberObject *n1 = [array objectAtIndex:i];
        GNumberObject *n2 = [array objectAtIndex:i+1];
        NSArray *tmp = [NSArray arrayWithObjects:n1, n2, nil];
        [result addObject:tmp];
    }
    return [NSArray arrayWithArray:result];
}
@end
