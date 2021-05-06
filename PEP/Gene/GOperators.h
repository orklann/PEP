//
//  GOperators.h
//  PEP
//
//  Created by Aaron Elkins on 5/6/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GPage;

// gs operator
@interface GgsOperator : NSObject {
    
}

@property (readwrite) NSString *gsName;

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;
@end

NS_ASSUME_NONNULL_END
