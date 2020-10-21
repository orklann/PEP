//
//  GBinaryData.m
//  PEP
//
//  Created by Aaron Elkins on 10/21/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GBinaryData.h"

@implementation GBinaryData

- (NSString*)getIndirectObjectHeader {
    return [NSString stringWithFormat:@"%d %d obj\n", self.objectNumber,
            self.generationNumber];
}
@end
