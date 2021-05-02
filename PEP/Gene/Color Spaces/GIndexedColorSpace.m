//
//  GIndexedColorSpace.m
//  PEP
//
//  Created by Aaron Elkins on 5/2/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GIndexedColorSpace.h"
#import "GObjects.h"
#import "GPage.h"
#import "GParser.h"

@implementation GIndexedColorSpace

+ (id)colorSpaceWithArray:(GArrayObject*)arrayObject page:(nullable GPage*)page {
    GIndexedColorSpace *cs = [[GIndexedColorSpace alloc] init];
    
    GObject *baseObject = [[arrayObject value] objectAtIndex:1];
    GColorSpace *baseColorSpace = nil;
    
    // Cunstruct base color space
    if ([baseObject type] == kNameObject) {
        baseColorSpace = [GColorSpace colorSpaceWithName:[(GNameObject*) baseObject value] page:page];
    } else if ([baseObject type] == kRefObject) {
        GArrayObject *a = [[page parser]
                           getObjectByRef:[(GRefObject*)baseObject
                                           getRefString]];
        baseColorSpace = [GColorSpace colorSpaceWithArray:a page:page];
    } else if ([baseObject type] == kArrayObject) {
        baseColorSpace = [GColorSpace
                          colorSpaceWithArray:(GArrayObject*)baseObject page:page];
    }
    
    [cs setBaseColorSpace:baseColorSpace];
    
    // Set numComps
    [cs setNumComps:[baseColorSpace numComps]];
    
    // Parse hival
    GNumberObject *hivalObject = [[arrayObject value] objectAtIndex:2];
    [cs setHival:[hivalObject intValue]];
    
    // Parse lookup table
    GObject *lookupObject = [[arrayObject value] objectAtIndex:3];
    if ([lookupObject type] == kRefObject) {
        GRefObject *ref = (GRefObject*)lookupObject;
        lookupObject = [[page parser] getObjectByRef:[ref getRefString]];
        
        if ([lookupObject type] == kStreamObject) {
            NSData *data = [(GStreamObject*)lookupObject getDecodedStreamContent];
            [cs setLookupTable:data];
        } else if ([lookupObject type] == kHexStringsObject) {
            NSString *s = [(GHexStringsObject*)lookupObject stringValue];
            NSData *data = [s dataUsingEncoding:NSASCIIStringEncoding];
            [cs setLookupTable:data];
            NSLog(@"Info: GIndexedColor Space parsing lookup table, which is a GHexStringObject, please verify it's correctness");
        }
    } else {
        NSLog(@"Error: GIndexedColorSpace paring lookup table, which is not a GRefObject, not implemented");
    }
    
    return cs;
}

- (NSColor*)mapColor:(GCommandObject*)cmd {
    NSArray *args = [cmd args];
    GNumberObject *indexObject = [args firstObject];
    int index = (int)[indexObject intValue];
    
    int numComps = [self numComps];
    int start = index * numComps;
    
    unsigned char* bytes = (unsigned char*)[_lookupTable bytes];
    
    NSColor *color;
    
    if (numComps == 1) {
        unsigned char val = (unsigned char)(*(bytes + start));
        float divided = (float)(val / 255.0);
        NSString *s = [NSString stringWithFormat:@"%f", divided];
        
        GParser *p = [GParser parser];
        [p setStream:[s dataUsingEncoding:NSASCIIStringEncoding]];
        [p parse];
        NSArray *result = [p objects];
        [cmd setArgs:result];
        color = [_baseColorSpace mapColor:cmd];
    } else if (numComps == 3) {
        unsigned char v1 = (unsigned char)(*(bytes + start));
        float divided1 = (float)(v1 / 255.0);
        
        unsigned char v2 = (unsigned char)(*(bytes + start + 1));
        float divided2 = (float)(v2 / 255.0);
        
        unsigned char v3 = (unsigned char)(*(bytes + start + 2));
        float divided3 = (float)(v3 / 255.0);
        
        NSString *s = [NSString stringWithFormat:@"%f %f %f", divided1, divided2,
                       divided3];
                
        GParser *p = [GParser parser];
        [p setStream:[s dataUsingEncoding:NSASCIIStringEncoding]];
        [p parse];
        NSArray *result = [p objects];
        [cmd setArgs:result];
        color = [_baseColorSpace mapColor:cmd];
    } else {
        NSLog(@"Error: GIndexedColorSpace mapColor: without handling numComps: %d", numComps);
    }
    
    return color;
}
@end
