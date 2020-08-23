//
//  GLexer.h
//  PEP
//
//  Created by Aaron Elkins on 8/22/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GToken : NSObject {
    int type;
    NSData *content;
}
+ (id)token;
@end


@interface GLexer : NSObject
{
    NSData *stream;
}
+ (id)lexer;
- (void)setStream:(NSData*)s;
- (NSData*)stream;
@end

NS_ASSUME_NONNULL_END
