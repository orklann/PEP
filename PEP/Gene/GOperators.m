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


@implementation GqOperator

+ (id)create {
    GqOperator *o = [[GqOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    CGContextSaveGState(context);
    [page saveGraphicsState];
}
@end


@implementation GQOperator

+ (id)create {
    GQOperator *o = [[GQOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    CGContextRestoreGState(context);
    [page restoreGraphicsState];
}
@end


@implementation GgOperator

+ (id)create {
    GgOperator *o = [[GgOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    // Set color space in graphic state
    GColorSpace *cs = [GColorSpace colorSpaceWithName:@"DeviceGray" page:page];
    [page.graphicsState setNonStrokeColorSpace:cs];
    
    // Set nonStrokeColor in graphic state
    NSColor *nonStrokeColor = [cs mapColor:_cmdObj];
    [page.graphicsState setNonStrokeColor:nonStrokeColor];
    
    // Also set fill color (nonStrokeColor) for context
    CGContextSetFillColorWithColor(context, [nonStrokeColor CGColor]);
}
@end


@implementation GGOperator

+ (id)create {
    GGOperator *o = [[GGOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    // Set color space in graphic state
    GColorSpace *cs = [GColorSpace colorSpaceWithName:@"DeviceGray" page:page];
    [page.graphicsState setStrokeColorSpace:cs];
    
    // Set strokeColor in graphic state
    NSColor *strokeColor = [cs mapColor:_cmdObj];
    [page.graphicsState setStrokeColor:strokeColor];
    
    // Also set stroke color (strokeColor) for context
    CGContextSetStrokeColorWithColor(context, [strokeColor CGColor]);
}
@end

@implementation GreOperator

+ (id)create {
    GreOperator *o = [[GreOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    NSArray *args = [_cmdObj args];
    CGFloat x = [[args objectAtIndex:0] getRealValue];
    CGFloat y = [[args objectAtIndex:1] getRealValue];
    CGFloat w = [[args objectAtIndex:2] getRealValue];
    CGFloat h = [[args objectAtIndex:3] getRealValue];
    NSRect rect = NSMakeRect(x, y, w, h);
    
    // Turn negative size of rect into positive size
    rect = CGRectStandardize(rect);
    [page.interpreter setCurrentPath:CGPathCreateMutable()];
    CGPathAddRect(page.interpreter.currentPath, NULL, rect);
}

@end


@implementation GfStarOperator

+ (id)create {
    GfStarOperator *o = [[GfStarOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    if ([[page graphicsState] overprintNonstroking]) {
        return ;
    }

    CGContextBeginPath(context);
    CGContextAddPath(context, page.interpreter.currentPath);
    NSColor *nonStrokeColor = [page.graphicsState nonStrokeColor];
    CGContextSetFillColorWithColor(context, [nonStrokeColor CGColor]);
    CGContextEOFillPath(context);
}

@end


@implementation GfOperator

+ (id)create {
    GfOperator *o = [[GfOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    if ([[page graphicsState] overprintNonstroking]) {
        return ;
    }
    
    CGContextBeginPath(context);
    CGContextAddPath(context, page.interpreter.currentPath);
    NSColor *nonStrokeColor = [page.graphicsState nonStrokeColor];
    CGContextSetFillColorWithColor(context, [nonStrokeColor CGColor]);
    CGContextFillPath(context);
}

@end


@implementation GWStarOperator

+ (id)create {
    GWStarOperator *o = [[GWStarOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    CGContextBeginPath(context);
    CGContextAddPath(context, page.interpreter.currentPath);
    CGContextEOClip(context);
}

@end

@implementation GWOperator

+ (id)create {
    GWOperator *o = [[GWOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    CGContextBeginPath(context);
    CGContextAddPath(context, page.interpreter.currentPath);
    CGContextClip(context);
}

@end


@implementation GnOperator

+ (id)create {
    GnOperator *o = [[GnOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    // Do nothing for n operator
}

@end
