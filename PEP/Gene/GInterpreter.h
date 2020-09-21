//
//  GInterpreter.h
//  PEP
//
//  Created by Aaron Elkins on 9/21/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GParser.h"

NS_ASSUME_NONNULL_BEGIN

@interface GInterpreter : NSObject {
    GParser *parser;
}

+ (id)create;
- (void)setParser:(GParser*)p;
- (void)eval:(CGContextRef)context;
@end

NS_ASSUME_NONNULL_END
