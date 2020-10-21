//
//  GEncoders.m
//  PEP
//
//  Created by Aaron Elkins on 10/21/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GEncoders.h"
#include <zlib.h>

// Use zlib in system to encode flate
NSData* encodeFlate(NSData *data) {
    uLong sourceLen = (uLong)[data length];
    int multiple = 2;
    const Bytef *source = (Bytef *)[data bytes];
    uLong destLen = sourceLen * multiple;
    Bytef *dest = (Bytef *)malloc(destLen);
    int ret = compress(dest, &destLen, source, sourceLen);
    if (ret == Z_OK) {
        NSData *d = [NSData dataWithBytes:(unsigned char*)dest length:destLen];
        free(dest);
        return d;
    }
    return nil;
}
