//
//  GFunction.m
//  PEP
//
//  Created by Aaron Elkins on 4/28/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GFunction.h"
#import "GObjects.h"
#import "GSampledFunction.h"

@implementation GFunction


+ (id)functionWithStreamObject:(GStreamObject*)streamObj {
    id obj = nil;
    GNumberObject *type = [[[streamObj dictionaryObject] value] objectForKey:@"FunctionType"];
    int functionType = [type intValue];
    if (functionType == 0) {
        obj = [GSampledFunction functionWithStreamObject:streamObj];
    }
    return obj;
}
@end
