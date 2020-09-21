//
//  GInterpreter.m
//  PEP
//
//  Created by Aaron Elkins on 9/21/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GInterpreter.h"

@implementation GInterpreter
+ (id)create {
    GInterpreter *o = [[GInterpreter alloc] init];
    return o;
}

- (void)setParser:(GParser*)p {
    parser = p;
}

- (void)eval:(CGContextRef)context {
    
}
@end
