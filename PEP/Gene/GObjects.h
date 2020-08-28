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
    kBooleanObject,
    kNumberObject
};

typedef enum {
    kIntSubtype,
    kRealSubtype
} NumberSubtype;

@interface GObject : NSObject {
    int type;
    NSData *rawContent;
}

+ (id)create;
- (void)setType:(int)t;
- (int)type;
- (void)setRawContent:(NSData*)d;
- (NSData *)rawContent;
@end

@interface GBooleanObject : GObject {
    BOOL value;
}

+ (id)create;
- (void)setValue:(BOOL)v;
- (BOOL)value;
- (void)parse;
@end

@interface GNumberObject : GObject {
    int intValue;
    double realValue;
    NumberSubtype subtype;
}

+ (id)create;
- (int)subtype;
- (void)setIntValue:(int)v;
- (int)intValue;
- (void)setRealValue:(double)v;
- (double)realValue;
- (void)parse;
@end

NS_ASSUME_NONNULL_END
