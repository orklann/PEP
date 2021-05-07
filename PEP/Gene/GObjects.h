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

BOOL isValidCommandCharater(unichar ch);

@class GParser;

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
    kRefObject,
    kCommandObject,
    kEndObject
} ObjectType;

typedef enum {
    kIntSubtype,
    kRealSubtype
} NumberSubtype;

// Get command arguments
NSArray *getCommandArgs(NSArray *objects, unsigned int argsNumber);

// Get dynamic command arguments
NSArray *getDynamicCommandArgs(NSArray *objects);

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
- (NSString*)toString;
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
- (double)getRealValue;
- (void)parse;
- (NSString*)toString;
@end

@interface GLiteralStringsObject : GObject {
    NSString *value;
}

+ (id)create;
- (void)setValue:(NSString*)v;
- (NSString *)value;
- (void)parse;
- (NSString*)toString;
@end

@interface GHexStringsObject : GObject {
    NSData *value;
}

+ (id)create;
- (void)setValue:(NSData*)v;
- (NSData *)value;
- (void)parse;
- (NSString*)stringValue;
- (NSString*)toString;
- (NSString*)rawString;
- (long)integerValue;
- (NSString*)utf16BEString;
@end

@interface GNameObject : GObject {
    NSString *value;
    NSData *lexerRawContent;
}

+ (id)create;
- (void)setLexerRawContent:(NSData*)d;
- (void)setValue:(NSString*)s;
- (NSString *)value;
- (void)parse;
- (NSString*)toString;
@end

@interface GArrayObject : GObject {
    NSArray *value;
}

+ (id)create;
- (void)setValue:(NSArray*)s;
- (NSArray *)value;
- (void)parse;
- (NSString*)toString;
@end

@interface GDictionaryObject : GObject {
    NSMutableDictionary *value;
}

+ (id)create;
- (void)setValue:(NSMutableDictionary*)s;
- (NSMutableDictionary *)value;
- (void)parse;
- (NSString*)getRawContentString;
- (NSString*)toString;
@end

@interface GStreamObject : GObject {
    GDictionaryObject *dictionary;
    NSData *streamContent;
}

// Start position in stream of stream content
@property (readwrite) unsigned int startContentPos;
@property (readwrite) GParser *parser;

+ (id)create;
- (void)setDictionaryObject:(GDictionaryObject*)d;
- (GDictionaryObject *)dictionaryObject;
- (void)setStreamContent:(NSData *)c;
- (NSData*)streamContent;
- (void)parse;
- (NSData*)getDecodedStreamContent;
/*
 * Return all raw content of the stream object including dictionary header,
 * and stream content
 */
- (NSData*)getAllContent;
@end

@interface GIndirectObject : GObject {
    id object;
    int objectNumber;
    int generationNumber;
}

@property (readwrite) unsigned int startPos;
@property (readwrite) GParser *parser;

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
+ (id)create;
- (NSString*)toString;
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
- (NSString*)getRefString;
- (NSString*)toString;
@end

@interface GEndObject : GObject
@end

@interface GXRefEntry: NSObject {
    unsigned int objectNumber;
    unsigned int offset;
    unsigned int generationNumber;
    unsigned char inUse;
}
+ (id)create;
- (void)setObjectNumber:(unsigned int)n;
- (unsigned int)objectNumber;
- (void)setOffset:(unsigned int)os;
- (unsigned int)offset;
- (void)setGenerationNumber:(unsigned int)g;
- (unsigned int)generationNumber;
- (void)setInUse:(unsigned char)i;
- (unsigned char)inUse;
@end


// Command Object (a.k.a operators) describe how PDF page content are shown,
// And are in the content of PDF Page
@interface GCommandObject : GObject {
    NSString *cmd;
    NSArray *args;
}

+ (id)create;
- (void)setCmd:(NSString *)c;
- (NSString *)cmd;
- (void)setArgs:(NSArray *)a;
- (NSArray*)args;
- (void)parse;
- (GCommandObject*)clone;
@end
NS_ASSUME_NONNULL_END
