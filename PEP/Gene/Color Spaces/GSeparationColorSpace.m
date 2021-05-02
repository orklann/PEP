//
//  GSeparationColorSpace.m
//  PEP
//
//  Created by Aaron Elkins on 5/1/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GSeparationColorSpace.h"
#import "GObjects.h"
#import "GPage.h"
#import "GParser.h"
#import "GFunction.h"
#import "GAlternateColorSpace.h"

@implementation GSeparationColorSpace

+ (id)colorSpaceWithArray:(GArrayObject*)arrayObject page:(nullable GPage*)page {
    id cs;
    GObject *alternateObject = [[arrayObject value] objectAtIndex:2];
    GColorSpace *baseColorSpace = nil;
    
    GFunction *function = nil;
    GObject *functionObject = [[arrayObject value] objectAtIndex:3];
    
    // Cunstruct base color space
    if ([alternateObject type] == kNameObject) {
        baseColorSpace = [GColorSpace colorSpaceWithName:[(GNameObject*) alternateObject value] page:page];
    } else if ([alternateObject type] == kRefObject) {
        GArrayObject *a = [[page parser]
                           getObjectByRef:[(GRefObject*)alternateObject
                                           getRefString]];
        baseColorSpace = [GColorSpace colorSpaceWithArray:a page:page];
    } else if ([alternateObject type] == kArrayObject) {
        baseColorSpace = [GColorSpace
                          colorSpaceWithArray:(GArrayObject*)alternateObject page:page];
    }
    
    // Construct funtion object
    if ([functionObject type] == kRefObject) {
        GRefObject *ref = (GRefObject*)functionObject;
        GStreamObject *stream = [[page parser] getObjectByRef:[ref getRefString]];
        function = [GFunction functionWithStreamObject:stream];
    } else {
        NSLog(@"Error: function object in Saparation color space array is not a ref object");
    }
    
    cs = [GAlternateColorSpace colorSpace:baseColorSpace function:function];
    
    return cs;
}

- (NSColor*)mapColor:(GCommandObject*)cmd {
    return [NSColor blackColor];
}
@end
