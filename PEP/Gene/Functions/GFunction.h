//
//  GFunction.h
//  PEP
//
//  Created by Aaron Elkins on 4/28/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * See 7.10.1, PDF specification
 */
float interpolate(float x, float xmin, float xmax, float ymin, float ymax);

@class GStreamObject;

@interface GFunction : NSObject {
    
}

+ (id)functionWithStreamObject:(GStreamObject*)streamObj;
- (NSArray*)eval:(NSArray*)inputs;
@end

NS_ASSUME_NONNULL_END
