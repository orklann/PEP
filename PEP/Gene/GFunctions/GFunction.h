//
//  GFunction.h
//  PEP
//
//  Created by Aaron Elkins on 4/28/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class GStreamObject;

@interface GFunction : NSObject {
    
}

+ (id)functionWithStreamObject:(GStreamObject*)streamObj;
@end

NS_ASSUME_NONNULL_END
