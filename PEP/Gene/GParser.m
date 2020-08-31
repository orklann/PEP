//
//  GParser.m
//  PEP
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GParser.h"
#import "GObjects.h"

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
    NSMutableData *d = [NSMutableData dataWithBytes:[s bytes]
                                             length:[s length]];
    // End stream with '\0' to ensure it will stop parsing
    // Because GLexer need '\0' at the end to generate kEndToken
    [d appendBytes:"\0" length:1];
    [lexer setStream:d];
    objects = [NSMutableArray array];
}

- (NSMutableArray*)objects {
    return objects;
}

- (NSMutableArray*)parseWithTokens:(NSMutableArray*)tokens {
    NSMutableArray *array = [NSMutableArray array];
    NSUInteger i = 0;
    for (i = 0; i < [tokens count]; i++) {
        GToken *token = [tokens objectAtIndex:i];
        TokenType type = [token type];
        switch (type) {
            case kNullObjectToken:
            {
                GNullObject *o = [GNullObject create];
                [o setType:kNullObject];
                [array addObject:o];
                break;
            }
            case kBooleanToken:
            {
                GBooleanObject *o = [GBooleanObject create];
                [o setType:kBooleanObject];
                [o setRawContent:[token content]];
                [o parse];
                [array addObject:o];
                break;
            }
            
            case kNumberToken:
            {
                if (i + 2 <= [tokens count] - 1) {
                    GToken *token2 = [tokens objectAtIndex:i+1];
                    GToken *token3 = [tokens objectAtIndex:i+2];
                    TokenType type3 = [token3 type];
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
                        
                        [array addObject:indirectObj];
                        i += 2;
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
                        [array addObject:ref];
                        i += 2;
                        break;
                    }
                }
                GNumberObject *o = [GNumberObject create];
                [o setType:kNumberObject];
                [o setRawContent:[token content]];
                [o parse];
                [array addObject:o];
                break;
            }
            
            case kLiteralStringsToken:
            {
                GLiteralStringsObject *o = [GLiteralStringsObject create];
                [o setType:kLiteralStringsObject];
                [o setRawContent:[token content]];
                [o parse];
                [array addObject:o];
                break;
            }
                
            case kHexadecimalStringsToken:
            {
                GHexStringsObject *o = [GHexStringsObject create];
                [o setType:kHexStringsObject];
                [o setRawContent:[token content]];
                [o parse];
                [array addObject:o];
                break;
            }
            case kNameObjectToken:
            {
                GNameObject *o = [GNameObject create];
                [o setType:kNameObject];
                [o setRawContent:[token content]];
                [o parse];
                [array addObject:o];
                break;
            }
            case kArrayObjectToken:
            {
                GArrayObject *o = [GArrayObject create];
                [o setType:kArrayObject];
                [o setRawContent:[token content]];
                [o parse];
                [array addObject:o];
                break;
            }
            case kDictionaryObjectToken:
            {
                if (i+1 <= [tokens count] - 1){
                    GToken *token2 = [tokens objectAtIndex:i+1];
                    TokenType type2 = [token2 type];
                    if (type2 == kStreamContentToken) {
                        GDictionaryObject *o = [GDictionaryObject create];
                        [o setType:kDictionaryObject];
                        [o setRawContent:[token content]];
                        [o parse];
                        
                        GStreamObject *s = [GStreamObject create];
                        [s setType:kStreamObject];
                        [s setDictionaryObject:o];
                        [s setStreamContent:[token2 content]];
                        [s parse];
                        [array addObject:s];
                        i++;
                    }
                    break;
                }
                GDictionaryObject *o = [GDictionaryObject create];
                [o setType:kDictionaryObject];
                [o setRawContent:[token content]];
                [o parse];
                [array addObject:o];
                break;
            }
            case kEndToken:
            {
                break;
            }
            default:
                break;
        }
    }
    return array;
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
@end
