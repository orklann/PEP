//
//  GBinaryData.m
//  PEP
//
//  Created by Aaron Elkins on 10/21/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GBinaryData.h"

@implementation GBinaryData
+ (id)create {
    GBinaryData *d = [[GBinaryData alloc] init];
    return d;
}

- (NSString*)getIndirectObjectHeader {
    return [NSString stringWithFormat:@"%d %d obj\n", self.objectNumber,
            self.generationNumber];
}

- (NSData*)getDataAsIndirectObject {
    NSMutableData *data = [NSMutableData data];
    // Add indirect object header
    [data appendData:[[self getIndirectObjectHeader] dataUsingEncoding:NSASCIIStringEncoding]];
    // Add content
    [data appendData:self.data];
    // Add end
    NSString *end = @"endobj\n";
    [data appendData:[end dataUsingEncoding:NSASCIIStringEncoding]];
    return data;
}
@end
