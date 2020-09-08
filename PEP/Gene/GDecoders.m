//
//  GDecoders.c
//  PEP
//
//  Created by Aaron Elkins on 9/8/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#include "GDecoders.h"
#include <zlib.h>

NSData* decodeFlate(NSData *data) {
    uLong sourceLen = (uLong)[data length];
    int multiple = 1024;
    const Bytef *source = (Bytef *)[data bytes];
    uLong destLen = sourceLen * multiple;
    Bytef *dest = (Bytef *)malloc(destLen);
    int ret = uncompress(dest, &destLen, source, sourceLen);
    if (ret == Z_OK) {
        NSData *d = [NSData dataWithBytes:(unsigned char*)dest length:destLen];
        return d;
    }
    return nil;
}
