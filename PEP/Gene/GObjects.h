//
//  GObjects.h
//  PEP
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef enum {
    kUnknownObject,
    kBooleanObject,
    kNumberObject,
    kLiteralStringsObject,
    kHexStringsObject
} ObjectType;

typedef enum {
    kIntSubtype,
    kRealSubtype
} NumberSubtype;

@interface GObject : NSObject {
    ObjectType type;
    NSData *rawContent;
    unsigned int pos;
}

+ (id)create;
- (void)setType:(ObjectType)t;
- (ObjectType)type;
- (void)setRawContent:(NSData*)d;
- (NSData *)rawContent;
- (unsigned char)currentChar;
- (unsigned char)nextChar;
- (unsigned char)peekNextChar;
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
- (NumberSubtype)subtype;
- (void)setIntValue:(int)v;
- (int)intValue;
- (void)setRealValue:(double)v;
- (double)realValue;
- (void)parse;
@end

@interface GLiteralStringsObject : GObject {
    NSString *value;
}

+ (id)create;
- (void)setValue:(NSString*)v;
- (NSString *)value;
- (void)parse;
@end

@interface GHexStringsObject : GObject {
    NSData *value;
}

+ (id)create;
- (void)setValue:(NSData*)v;
- (NSData *)value;
- (void)parse;
@end


NS_ASSUME_NONNULL_END
