//
//  GObjects.h
//  PEP
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//
//
//
// This file implement PDF's 8 basic types of objects and some extra objects.
//
// PDF includes eight basic types of objects: Boolean values, Integer and
// Real numbers, Strings, Names, Arrays, Dictionaries, Streams, and the
// null object.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef enum {
    kUnknownObject,
    kBooleanObject,
    kNumberObject,
    kLiteralStringsObject,
    kHexStringsObject,
    kNameObject,
    kArrayObject,
    kDictionaryObject,
    kStreamObject,
    kIndirectObject,
    kNullObject,
    kRefObject
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

@interface GNameObject : GObject {
    NSString *value;
}

+ (id)create;
- (void)setValue:(NSString*)s;
- (NSString *)value;
- (void)parse;
@end

@interface GArrayObject : GObject {
    NSArray *value;
}

+ (id)create;
- (void)setValue:(NSArray*)s;
- (NSArray *)value;
- (void)parse;
@end

@interface GDictionaryObject : GObject {
    NSMutableDictionary *value;
}

+ (id)create;
- (void)setValue:(NSMutableDictionary*)s;
- (NSMutableDictionary *)value;
- (void)parse;
@end

@interface GStreamObject : GObject {
    GDictionaryObject *dictionary;
    NSData *streamContent;
}

+ (id)create;
- (void)setDictionaryObject:(GDictionaryObject*)d;
- (GDictionaryObject *)dictionaryObject;
- (void)setStreamContent:(NSData *)c;
- (NSData*)streamContent;
- (void)parse;
@end

@interface GIndirectObject : GObject {
    id object;
    int objectNumber;
    int generationNumber;
}

+ (id)create;
- (void)setObjectNumber:(int)n;
- (int)objectNumber;
- (void)setGenerationNumber:(int)n;
- (int)generationNumber;
- (void)setObject:(id)o;
- (id)object;
- (void)parse;
@end

@interface GNullObject : GObject

@end

@interface GRefObject : GObject {
    int objectNumber;
    int generationNumber;
}

+ (id)create;
- (void)setObjectNumber:(int)n;
- (int)objectNumber;
- (void)setGenerationNumber:(int)n;
- (int)generationNumber;
- (void)parse;
@end
NS_ASSUME_NONNULL_END
