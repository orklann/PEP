//
//  GDecoders.h
//  PEP
//
//  Created by Aaron Elkins on 9/8/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#ifndef GDecoders_h
#define GDecoders_h

#import <Foundation/Foundation.h>
#include <stdio.h>

NSData* decodeFlate(NSData *data);
NSData *decodeASCII85(NSData *data);
#endif /* GDecoders_h */
