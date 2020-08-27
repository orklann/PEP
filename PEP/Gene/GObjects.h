//
//  GObjects.h
//  PEP
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
enum {
    kUnknownObject,
    kBooleanObject
};

@interface GBooleanObject : NSObject {
    int type;
    BOOL value;
    NSData *rawContent;
}
+ (id)create;
- (void)setType:(int)t;
- (int)type;
- (void)setValue:(BOOL)v;
- (BOOL)value;
- (void)setRawContent:(NSData*)d;
- (NSData *)rawContent;
@end

NS_ASSUME_NONNULL_END
