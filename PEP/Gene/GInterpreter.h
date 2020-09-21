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

BOOL isCommand(NSString *cmd, NSString *cmd2);

@interface GInterpreter : NSObject {
    GParser *parser;
    NSData *input;
}

+ (id)create;
- (void)setParser:(GParser*)p;
- (void)setInput:(NSData *)d;
- (void)eval:(CGContextRef)context;
@end

NS_ASSUME_NONNULL_END
