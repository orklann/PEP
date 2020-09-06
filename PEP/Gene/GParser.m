//
//  GParser.m
//  PEP
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GParser.h"
#import "GObjects.h"

XRefType xrefType(NSString *line) {
    if ([line containsString:@"f"] || [line containsString:@"n"]) {
        return kXRefEntry;
    }
    return kXRefSubsectionHeader;
}

BOOL isTrailerLine(NSString *line) {
    if ([line containsString:@"trailer"]) {
        return YES;
    }
    return NO;
}

@implementation GParser

+ (id)parser {
    GParser *p = [[GParser alloc] init];
    GLexer *l = [GLexer lexer];
    [p setLexer:l];
    return p;
}

- (void)setLexer:(GLexer*)l {
    lexer = l;
}

- (GLexer*)lexer {
    return lexer;
}

- (void)setStream:(NSData*)s {
    [lexer setStream:s];
    objects = [NSMutableArray array];
}

- (NSMutableArray*)objects {
    return objects;
}

- (id)parseNextObject {
    GToken *token = [lexer nextToken];
    TokenType type = [token type];
    id o;
    switch (type) {
        case kNullObjectToken:
        {
            o = [GNullObject create];
            [(GNullObject *)o setType:kNullObject];
            break;
        }
        case kBooleanToken:
        {
            o = [GBooleanObject create];
            [(GBooleanObject*)o setType:kBooleanObject];
            [(GBooleanObject*)o setRawContent:[token content]];
            [(GBooleanObject*)o parse];
            break;
        }
        case kNumberToken:
        {
            unsigned int rewindPos = [lexer pos];
            GToken *token2 = [lexer nextToken];
            GToken *token3 = [lexer nextToken];
            TokenType type3 = [token3 type];
            if ([token3 type] != kEndToken) {
                if (type3 == kIndirectObjectContentToken) {
                    // Object number
                    GNumberObject *objNumberObject = [GNumberObject create];
                    [objNumberObject setType:kNumberObject];
                    [objNumberObject setRawContent:[token content]];
                    [objNumberObject parse];
                    
                    // Generation number
                    GNumberObject *generationNumberObject = [GNumberObject create];
                    [generationNumberObject setType:kNumberObject];
                    [generationNumberObject setRawContent:[token2 content]];
                    [generationNumberObject parse];
                    
                    // Object in indirect object
                    GIndirectObject *indirectObj = [GIndirectObject create];
                    [indirectObj setType:kIndirectObject];
                    [indirectObj setObjectNumber:[objNumberObject intValue]];
                    [indirectObj setGenerationNumber:[generationNumberObject intValue]];
                    [indirectObj setRawContent:[token3 content]];
                    [indirectObj parse];
                    
                    o = indirectObj;
                    break;
                } else if (type3 == kRefToken) {
                    // Object number
                    GNumberObject *objNumberObject = [GNumberObject create];
                    [objNumberObject setType:kNumberObject];
                    [objNumberObject setRawContent:[token content]];
                    [objNumberObject parse];
                    
                    // Generation number
                    GNumberObject *generationNumberObject = [GNumberObject create];
                    [generationNumberObject setType:kNumberObject];
                    [generationNumberObject setRawContent:[token2 content]];
                    [generationNumberObject parse];
                    
                    // Object in indirect object
                    GRefObject *ref = [GRefObject create];
                    [ref setType:kRefObject];
                    [ref setObjectNumber:[objNumberObject intValue]];
                    [ref setGenerationNumber:[generationNumberObject intValue]];
                    [ref parse];
                    
                    o = ref;
                    break;
                }
            }
            o = [GNumberObject create];
            [(GNumberObject*)o setType:kNumberObject];
            [(GNumberObject*)o setRawContent:[token content]];
            [(GNumberObject*)o parse];
            [lexer setPos: rewindPos];
            break;
        }
        case kLiteralStringsToken:
        {
            o = [GLiteralStringsObject create];
            [(GLiteralStringsObject *)o setType:kLiteralStringsObject];
            [(GLiteralStringsObject *)o setRawContent:[token content]];
            [(GLiteralStringsObject *)o parse];
            break;
        }
        case kHexadecimalStringsToken:
        {
            o = [GHexStringsObject create];
            [(GHexStringsObject *)o setType:kHexStringsObject];
            [(GHexStringsObject *)o setRawContent:[token content]];
            [(GHexStringsObject *)o parse];
            break;
        }
        case kNameObjectToken:
        {
            o = [GNameObject create];
            [(GNameObject *)o setType:kNameObject];
            [(GNameObject *)o setRawContent:[token content]];
            [(GNameObject *)o parse];
            break;
        }
        case kArrayObjectToken:
        {
            o = [GArrayObject create];
            [(GArrayObject *)o setType:kArrayObject];
            [(GArrayObject *)o setRawContent:[token content]];
            [(GArrayObject *)o parse];
            break;
        }
        case kDictionaryObjectToken:
        {
            unsigned int rewindPos = [lexer pos];
            GToken *token2 = [lexer nextToken];
            TokenType type2 = [token2 type];
            if (type2 != kEndToken){
                if (type2 == kStreamContentToken) {
                    GDictionaryObject *dict = [GDictionaryObject create];
                    [dict setType:kDictionaryObject];
                    [dict setRawContent:[token content]];
                    [dict parse];
                    
                    GStreamObject *s = [GStreamObject create];
                    [s setType:kStreamObject];
                    [s setDictionaryObject:dict];
                    [s setStreamContent:[token2 content]];
                    [s parse];
                    
                    o = s;
                    break;
                }
            }
            o = [GDictionaryObject create];
            [(GDictionaryObject *)o setType:kDictionaryObject];
            [(GDictionaryObject *)o setRawContent:[token content]];
            [(GDictionaryObject *)o parse];
            [lexer setPos:rewindPos];
            break;
        }
        case kEndToken:
        {
            o = [GEndObject create];
            [(GEndObject*)o setType:kEndObject];
            break;
        }
        default:
            break;
    }
    return o;
}

- (void)parse {
    id o = [self parseNextObject];
    while([(GObject*)o type] != kEndObject) {
        [objects addObject:o];
        o = [self parseNextObject];
    }
}

- (unsigned int)getStartXRef {
    // Set pos to the end
    unsigned int end = (unsigned int)[[lexer stream] length] - 1;
    [lexer setPos:end];
    unsigned char ch = [lexer currentChar];
    unsigned int pos = end;
    unsigned char *bytes = (unsigned char*)[[lexer stream] bytes];
    NSMutableData *data = [NSMutableData data];
    while (ch != 'f') {
        if (isdigit(ch)) {
            [data appendBytes:(unsigned char*)&ch length:1];
        }
        pos -= 1;
        ch = *(bytes + pos);
    }
    NSInteger i;
    NSMutableString *s = [NSMutableString string];
    unsigned char *bytes2 = (unsigned char*)[data bytes];
    for (i = [data length] - 1; i >= 0; i--) {
        unsigned char ch = *(bytes2 + i);
        [s appendFormat:@"%c", ch];
    }
    return (unsigned int)[s intValue];
}

- (NSDictionary *)parseXRef {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    unsigned int startXRef = [self getStartXRef];
    [[self lexer] setPos:startXRef];
    
    // Skip keyword `xref`
    NSString *line = [[self lexer] nextLine];
    // Skip subsection header
    while (true) {
        line = [[self lexer] nextLine];
        if (xrefType(line) == kXRefSubsectionHeader && !isTrailerLine(line)) {
            NSString *buf = [line substringWithRange:NSMakeRange(0, [line length])];
            unsigned int startObjectNumber, objectsCount;
            sscanf((const char*)[buf UTF8String], "%d %d", &startObjectNumber, &objectsCount);
            NSUInteger i;
            for (i = 0; i < objectsCount; i++) {
                // All lines here are xref entry
                line = [[self lexer] nextLine];
                NSString *buf = [line substringWithRange:NSMakeRange(0, 18)];
                unsigned int offset, generationNumber;
                unsigned char inUse;
                sscanf((const char*)[buf UTF8String], "%d %d %c", &offset, &generationNumber, &inUse);
                NSString *key = [NSString stringWithFormat:@"%d-%d",
                               (unsigned int)(startObjectNumber + i), generationNumber];
                GXRefEntry *x = [GXRefEntry create];
                [x setObjectNumber:(unsigned int)(startObjectNumber + i)];
                [x setOffset:offset];
                [x setGenerationNumber:generationNumber];
                [x setInUse:inUse];
                [dict setValue:x forKey:key];
            }
        }
        if (isTrailerLine(line)) {
            break;
        }
    }
    return dict;
}
@end
