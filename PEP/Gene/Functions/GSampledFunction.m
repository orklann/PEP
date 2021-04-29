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

/*
 * Refer pdf.js:
 * https://github.com/mozilla/pdf.js/blob/master/src/core/function.js#L142
 */
- (NSArray*)getSamples {
    NSMutableArray *result = [NSMutableArray array];
    int i, ii;
    int length = 1;
    for (i = 0, ii = (int)[_size count]; i < ii; i++) {
        int a = [[_size objectAtIndex:i] intValue];
        length *= a;
    }
    
    length *= _outputSize;
    
    int codeSize = 0;
    int codeBuf = 0;
    // 32 is a valid bps so shifting won't work
    float sampleMul = 1.0 / (pow(2.0, _bps) - 1);
    
    NSData *stream = [streamObj getDecodedStreamContent];
    unsigned char *strBytes = (unsigned char*)[stream bytes];
    int strIdx = 0;
    for (int i = 0; i < length; i++) {
        while (codeSize < _bps) {
            codeBuf <<= 8;
            codeBuf |= (unsigned char)(*(strBytes + strIdx));
            strIdx += 1;
            codeSize += 8;
        }
        codeSize -= _bps;
        float a = (codeBuf >> codeSize) * sampleMul;
        NSNumber *n = [NSNumber numberWithFloat:a];
        [result addObject:n];
        codeBuf &= (1 << codeSize) - 1;
    }
    return [NSArray arrayWithArray:result];
}

/*
 * Refer pdf.js code:
 * https://github.com/mozilla/pdf.js/blob/master/src/core/function.js#L237
 */
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
    
    // Samples
    _samples = [self getSamples];
}

/*
 * Refer to pdf.js:
 * https://github.com/mozilla/pdf.js/blob/0acd801b1e66c52f6c9a5bae2486f4865277d5aa/src/core/function.js#L309
 */

- (NSArray*)eval:(NSArray*)inputs {
    NSMutableArray *result = [NSMutableArray array];
    int m = _inputSize;
    int n = _outputSize;
    
    // Building the cube vertices: its part and sample index
    // http://rjwagner49.com/Mathematics/Interpolation.pdf
    int cubeVertices = 1 << m;
    NSMutableArray *cubeN = [NSMutableArray array];
    NSMutableArray *cubeVertex = [NSMutableArray array];
    int i, j;
    for (j = 0; j < cubeVertices; j++) {
        NSNumber *n = [NSNumber numberWithInt:1];
        [cubeN addObject:n];
        NSNumber *v = [NSNumber numberWithInt:0];
        [cubeVertex addObject:v];
    }
    
    int k = n,
        pos = 1;
    
    // Map x_i to y_j for 0 <= i < m using the sampled function.
    for (i = 0; i < m; ++i) {
        // x_i' = min(max(x_i, Domain_2i), Domain_2i+1)
        float domain_2i = [[[_domain objectAtIndex:i] firstObject] getRealValue];
        float domain_2i_1 = [[[_domain objectAtIndex:i] lastObject] getRealValue];
        float src = [[inputs objectAtIndex:i] floatValue];
        float xi = MIN(MAX(src, domain_2i), domain_2i_1);

        // e_i = Interpolate(x_i', Domain_2i, Domain_2i+1,
        //                   Encode_2i, Encode_2i+1)
        float encode_2i = [[[_encode objectAtIndex:i] firstObject] getRealValue];
        float encode_2i_1 = [[[_encode objectAtIndex:i] lastObject] getRealValue];
        float e = interpolate(xi, domain_2i, domain_2i_1, encode_2i, encode_2i_1);

        // e_i' = min(max(e_i, 0), Size_i - 1)
        int size_i = [[_size objectAtIndex:i] intValue];
        e = MIN(MAX(e, 0), size_i - 1);

        // Adjusting the cube: N and vertex sample index
        int e0 = e < size_i - 1 ? floor(e) : e - 1; // e1 = e0 + 1;
        float n0 = e0 + 1 - e; // (e1 - e) / (e1 - e0);
        float n1 = e - e0; // (e - e0) / (e1 - e0);
        int offset0 = e0 * k;
        int offset1 = offset0 + k; // e1 * k
        for (j = 0; j < cubeVertices; j++) {
            if (j & pos) {
                float n = [[cubeN objectAtIndex:j] floatValue];
                n *= n1;
                NSNumber *num = [NSNumber numberWithFloat:n];
                [cubeN replaceObjectAtIndex:j withObject:num];
                
                int v = [[cubeVertex objectAtIndex:j] intValue];
                v += offset1;
                NSNumber *vNum = [NSNumber numberWithInt:v];
                [cubeVertex replaceObjectAtIndex:j withObject:vNum];
            } else {
                float n = [[cubeN objectAtIndex:j] floatValue];
                n *= n0;
                NSNumber *num = [NSNumber numberWithFloat:n];
                [cubeN replaceObjectAtIndex:j withObject:num];
 
                int v = [[cubeVertex objectAtIndex:j] intValue];
                v += offset0;
                NSNumber *vNum = [NSNumber numberWithInt:v];
                [cubeVertex replaceObjectAtIndex:j withObject:vNum];
            }
        }

        k *= size_i;
        pos <<= 1;
    }
    
    for (j = 0; j < n; ++j) {
        // Sum all cube vertices' samples portions
        float rj = 0;
        for (i = 0; i < cubeVertices; i++) {
            int vertex = [[cubeVertex objectAtIndex:i] intValue];
            float sample = [[_samples objectAtIndex:vertex + j] floatValue];
            float N = [[cubeN objectAtIndex:i] floatValue];
            rj += sample * N;
        }

        // r_j' = Interpolate(r_j, 0, 2^BitsPerSample - 1,
        //                    Decode_2j, Decode_2j+1)
        float decode_j_0 = [[[_decode objectAtIndex:j] firstObject] getRealValue];
        float decode_j_1 = [[[_decode objectAtIndex:j] lastObject] getRealValue];
        rj = interpolate(rj, 0, 1, decode_j_0, decode_j_1);

        // y_j = min(max(r_j, range_2j), range_2j+1)
        float range_j_0 = [[[_range objectAtIndex:j] firstObject] getRealValue];
        float range_j_1 = [[[_range objectAtIndex:j] lastObject] getRealValue];
        float yj = MIN(MAX(rj, range_j_0), range_j_1);
        
        // Add final value into ouput array
        NSNumber *finalValue = [NSNumber numberWithFloat:yj];
        [result addObject:finalValue];
    }
    
    return [NSArray arrayWithArray:result];
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
