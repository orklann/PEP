//
//  GCMap.m
//  PEP
//
//  Created by Aaron Elkins on 3/30/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GCMap.h"
#import "GObjects.h"
#import "GParser.h"

@implementation GCMap
+ (id)create {
    GCMap *cmap = [[GCMap alloc] init];
    return cmap;
}

- (void)eval {
    [self eval:[_stream getDecodedStreamContent]];
}

- (void)eval:(NSData*)data {
    _unicodeMaps = [NSMutableDictionary dictionary];
    GParser *parser = [GParser parser];
    [parser setStream:data];
    id object = [parser parseNextObject];
    while ([(GObject*)object type] != kEndObject) {
        if ([(GObject *)object type] == kCommandObject) {
            NSString *cmd = [(GCommandObject*)object cmd];
            if ([cmd isEqualToString:@"beginbfrange"]) {
                [self evalBeginBFRange:parser];
            } else if ([cmd isEqualToString:@"beginbfchar"]) {
                [self evalBeginBFChar:parser];
            }
        }
        object = [parser parseNextObject];
    }
}

- (void)setUnicodeMap:(int)i value:(NSString*)s {
    NSNumber *number = [NSNumber numberWithInt:i];
    [_unicodeMaps setObject:s forKey:number];
}

- (void)evalBeginBFRange:(GParser*)parser {
    NSString *line = [[parser lexer] nextLine];
    while(![line isEqualToString:@"endbfrange"]) {
        if ([line length] > 0) {
            GParser *p = [GParser parser];
            [p setStream:[line dataUsingEncoding:NSASCIIStringEncoding]];
            [p parse];
            NSArray *objs = [p objects];
            GObject *lastObject = [objs lastObject];
            GHexStringsObject *firstObject = [objs firstObject];
            GHexStringsObject *secondObject = [objs objectAtIndex:1];
            int firstValue = (int)[firstObject integerValue];
            int secondValue = (int)[secondObject integerValue];
            for (int i = firstValue; i <= secondValue; i++) {
                NSString *unicode;
                if ([(GObject*)lastObject type] == kHexStringsObject) {
                    unicode = [(GHexStringsObject*)lastObject utf16BEString];
                } else if ([(GObject*)lastObject type] == kArrayObject) {
                    GHexStringsObject *hexString = [[(GArrayObject*)lastObject value]
                                                        objectAtIndex:i - firstValue];
                    unicode = [hexString utf16BEString];
                }
                [self setUnicodeMap:i value:unicode];
            }
        }
        line = [[parser lexer] nextLine];
    }
}

- (void)evalBeginBFChar:(GParser*)parser {
    NSString *line = [[parser lexer] nextLine];
    while(![line isEqualToString:@"endbfchar"]) {
        if ([line length] > 0) {
            GParser *p = [GParser parser];
            [p setStream:[line dataUsingEncoding:NSASCIIStringEncoding]];
            [p parse];
            NSArray *objs = [p objects];
            GHexStringsObject *firstObject = [objs firstObject];
            GHexStringsObject *secondObject = [objs objectAtIndex:1];
            int firstValue = (int)[firstObject integerValue];
            NSString *unicode = [secondObject utf16BEString];
            [self setUnicodeMap:firstValue value:unicode];
        }
        line = [[parser lexer] nextLine];
    }
}
@end
