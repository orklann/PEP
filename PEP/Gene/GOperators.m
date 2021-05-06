//
//  GOperators.m
//  PEP
//
//  Created by Aaron Elkins on 5/6/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GOperators.h"
#import "GObjects.h"
#import "GPage.h"

@implementation GgsOperator

+ (id)create {
    GgsOperator *o = [[GgsOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    GDictionaryObject *extGStageDict = [[page.resources value]
                                        objectForKey:@"ExtGState"];
    
    GDictionaryObject *gsObject = [[extGStageDict value] objectForKey:_gsName];
    
    if ([gsObject type] == kRefObject) {
        gsObject = [page.parser getObjectByRef:[(GRefObject*)gsObject getRefString]];
    }
    
    GBooleanObject *op = [[gsObject value] objectForKey:@"op"];
    GBooleanObject *OP = [[gsObject value] objectForKey:@"OP"];
    
    [[page graphicsState] setOverprintStroking:[OP value]];
    
    if (op) {
        [[page graphicsState] setOverprintNonstroking:[op value]];
    } else {
        [[page graphicsState] setOverprintNonstroking:[OP value]];
    }
}
@end
