//
//  GDecoders.c
//  PEP
//
//  Created by Aaron Elkins on 9/8/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#include "GDecoders.h"
#include <zlib.h>
#include "GMisc.h"

// Use zlib in system to decode 
NSData* decodeFlate(NSData *data) {
    uLong sourceLen = (uLong)[data length];
    int multiple = 1024;
    const Bytef *source = (Bytef *)[data bytes];
    uLong destLen = sourceLen * multiple;
    Bytef *dest = (Bytef *)malloc(destLen);
    int ret = uncompress(dest, &destLen, source, sourceLen);
    if (ret == Z_OK) {
        NSData *d = [NSData dataWithBytes:(unsigned char*)dest length:destLen];
        free(dest);
        return d;
    }
    return nil;
}

NSData *decodeASCII85(NSData *data) {
    NSMutableData *result = [NSMutableData data];
    int value = 0;
    int bytesNumber = 0;
    unsigned char c[5];
    unsigned char *stream = (unsigned char *)[data bytes];
    int i = 0;
    for (i = 0; i < [data length]; i++) {
        unsigned char ascii = (unsigned char)(*(stream + i));
        if (ascii >= '!' && ascii <= 'u') {
            c[bytesNumber] = ascii - 33; // 33 is ascii `!`
            bytesNumber += 1;
            if (bytesNumber == 5) { // Get 5 encoded bytes
                unsigned char b[4]; // Store 4 decoded bytes
                value = c[0] * (85 * 85 * 85 * 85);
                value += c[1] * (85 * 85 * 85);
                value += c[2] * (85 * 85);
                value += c[3] * 85;
                value += c[4];
                
                // we calculate 4 decoded bytes from last to first
                b[3] = (int)(value % 256);
                b[2] = (int)((value - b[3]) / 256 % 256);
                b[1] = (int)((value - (b[2] * 256) - b[3]) / (256 * 256) % 256);
                b[0] = (int)((value - (b[1] * 256 * 256) - (b[2] * 256) - b[3]) / ( 256 * 256 * 256) % 256);
                
                [result appendBytes:(unsigned char*)b length:4];
                bytesNumber = 0;
            }
        } else if (ascii == 'z') {
            [result appendBytes:(unsigned char*)"\0\0\0\0" length:4];
        } else if (isWhiteSpaceChar(ascii)) {
            continue;
        } else if (ascii == '~') {
            if (bytesNumber > 1 && bytesNumber < 5) {
                for (int j = bytesNumber; j < 5; j++) {
                    c[j] = 'u' - 33;
                }
                unsigned char b[4]; // Store 4 decoded bytes
                value = c[0] * (85 * 85 * 85 * 85);
                value += c[1] * (85 * 85 * 85);
                value += c[2] * (85 * 85);
                value += c[3] * 85;
                value += c[4];
                
                // we calculate 4 decoded bytes from last to first
                b[3] = (int)(value % 256);
                b[2] = (int)((value - b[3]) / 256 % 256);
                b[1] = (int)((value - (b[2] * 256) - b[3]) / (256 * 256) % 256);
                b[0] = (int)((value - (b[1] * 256 * 256) - (b[2] * 256) - b[3]) / ( 256 * 256 * 256) % 256);
                
                // TODO: After padding 4 - bytesNumber of 'u's, we can just get bytesNumber-1 the decocded bytes
                //       Maybe buggy, let's see later
                [result appendBytes:(unsigned char*)b length:bytesNumber -1];
                break;
            }
        }
    }
    return [NSData dataWithData:result];
}
