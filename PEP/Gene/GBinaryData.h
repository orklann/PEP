//
//  GBinaryData.h
//  PEP
//
//  Created by Aaron Elkins on 10/21/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GBinaryData : NSObject

@property (readwrite) int objectNumber;
@property (readwrite) int generationNumber;
@property (readwrite) NSData *data;

- (NSString*)getIndirectObjectHeader;
@end

NS_ASSUME_NONNULL_END
