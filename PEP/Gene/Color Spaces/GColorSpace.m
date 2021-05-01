//
//  GColorSpace.m
//  PEP
//
//  Created by Aaron Elkins on 4/14/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GColorSpace.h"
#import "GDeviceGrayColorSpace.h"
#import "GDeviceRGBColorSpace.h"
#import "GICCBasedColorSpace.h"
#import "GSeparationColorSpace.h"
#import "GObjects.h"
#import "GPage.h"


@implementation GColorSpace

+ (id)colorSpaceWithName:(NSString*)colorSpaceName page:(nullable GPage*)page {
    id cs;
    if ([colorSpaceName isEqualToString:kDeviceGray]) {
        cs = [GDeviceGrayColorSpace colorSpaceWithName:colorSpaceName page:page];
    } else if ([colorSpaceName isEqualToString:kDeviceRGB]) {
        cs = [GDeviceRGBColorSpace colorSpaceWithName:colorSpaceName page:page];
    } else {
        GDictionaryObject *resource = [page resources];
        GDictionaryObject *colorSpaceDictionary = [[resource value] objectForKey:@"ColorSpace"];
        GObject *colorSpaceObject = [[colorSpaceDictionary value] objectForKey:colorSpaceName];
        if ([colorSpaceObject type] == kArrayObject) {
            cs = [self colorSpaceWithArray:(GArrayObject*)colorSpaceObject page:page];
        } else if ([colorSpaceObject type] == kRefObject) {
            GRefObject *ref = (GRefObject*)colorSpaceObject;
            GArrayObject *arrayObject = [[page parser] getObjectByRef:[ref
                                                                    getRefString]];
            cs = [self colorSpaceWithArray:arrayObject page:page];
        }
    }
    return cs;
}

+ (id)colorSpaceWithArray:(GArrayObject*)arrayObject page:(nullable GPage*)page {
    GNameObject *csNameObject = [[arrayObject value] firstObject];
    NSString *csName = [csNameObject value];
    id cs;
    if ([csName isEqualToString:kICCBased]) {
        GRefObject *ref = [[arrayObject value] objectAtIndex:1];
        GStreamObject *stream = [[page parser] getObjectByRef:[ref getRefString]];
        cs = [GICCBasedColorSpace colorSpace:stream page:page];
    } else if ([csName isEqualToString:kSeparation]) {
        cs = [GSeparationColorSpace colorSpaceWithArray:arrayObject page:page];
    }
    return cs;
}

/* This method does not matter, because we never call it, just to make compiler happy. */
- (NSColor*)mapColor:(GCommandObject*)cmd {
    return [NSColor blackColor];
}
@end
