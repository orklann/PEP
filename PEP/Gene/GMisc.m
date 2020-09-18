//
//  GMisc.m
//  PEP
//
//  Created by Aaron Elkins on 9/18/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GMisc.h"

void printData(NSData *data) {
    NSUInteger i;
    unsigned char * bytes = (unsigned char*)[data bytes];
    for (i = 0; i < [data length]; i++) {
        printf("%c", (unsigned char)(*(bytes+i)));
    }
    printf("\n");
}
