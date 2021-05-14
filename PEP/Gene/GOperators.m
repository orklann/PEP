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
    GDictionaryObject *extGStateDict = [[page.resources value]
                                        objectForKey:@"ExtGState"];
    
    if ([extGStateDict type] == kRefObject) {
        extGStateDict = [page.parser getObjectByRef:[(GRefObject*)extGStateDict getRefString]];
    }
    
    GDictionaryObject *gsObject = [[extGStateDict value] objectForKey:_gsName];
    
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

- (NSString*)compile {
    return [NSString stringWithFormat:@"/%@ gs\n", _gsName];
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

- (NSString*)compile {
    return @"q\n";
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

- (NSString*)compile {
    return @"Q\n";
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

- (NSString*)compile {
    NSArray *args = [_cmdObj args];
    return [NSString stringWithFormat:@"%f g\n", [[args firstObject] getRealValue]];
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

- (NSString*)compile {
    NSArray *args = [_cmdObj args];
    return [NSString stringWithFormat:@"%f G\n", [[args firstObject] getRealValue]];
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

- (NSString*)compile {
    NSArray *args = [_cmdObj args];
    CGFloat x = [[args objectAtIndex:0] getRealValue];
    CGFloat y = [[args objectAtIndex:1] getRealValue];
    CGFloat w = [[args objectAtIndex:2] getRealValue];
    CGFloat h = [[args objectAtIndex:3] getRealValue];
    return [NSString stringWithFormat:@"%f %f %f %f re\n", x, y, w, h];
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
    page.interpreter.currentPath = CGPathCreateMutable();
}

- (NSString*)compile {
    return @"f*\n";
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
    page.interpreter.currentPath = CGPathCreateMutable();
}

- (NSString*)compile {
    return @"f\n";
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

- (NSString*)compile {
    return @"W*\n";
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

- (NSString*)compile {
    return @"W\n";
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

- (NSString*)compile {
    return @"n\n";
}
@end


@implementation GcsOperator

+ (id)create {
    GcsOperator *o = [[GcsOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    // Set color space in graphic state for non stroke color space
    GColorSpace *cs = [GColorSpace colorSpaceWithName:_colorSpaceName page:page];
    [page.graphicsState setNonStrokeColorSpace:cs];
}

- (NSString*)compile {
    return [NSString stringWithFormat:@"/%@ cs\n", _colorSpaceName];
}
@end


@implementation GscnOperator

+ (id)create {
    GscnOperator *o = [[GscnOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    GColorSpace *cs = [page.graphicsState nonStrokeColorSpace];
    
    // Set nonStrokeColor in graphic state
    // Why clone? Because mapColor: will modify args in GCommandObject
    GCommandObject *cloneCmd = [_cmdObj clone];
    NSColor *nonStrokeColor = [cs mapColor:cloneCmd];
    [page.graphicsState setNonStrokeColor:nonStrokeColor];
    
    // Also set fill color (nonStrokeColor) for context
    CGContextSetFillColorWithColor(context, [nonStrokeColor CGColor]);
}

- (NSString*)compile {
    NSArray *args = [_cmdObj args];
    NSMutableString *ms = [NSMutableString string];
    for (GObject *o in args) {
        if ([o type] == kNumberObject) {
            [ms appendFormat:@"%f ", [(GNumberObject*)o getRealValue]];
        } else if ([o type] == kNameObject) {
            [ms appendFormat:@"/%@ ", [(GNameObject*)o value]];
        }
    }
    [ms appendFormat:@"scn\n"];
    return ms;
}
@end


@implementation GmOperator

+ (id)create {
    GmOperator *o = [[GmOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    NSArray *args = [_cmdObj args];
    CGFloat x = [[args objectAtIndex:0] getRealValue];
    CGFloat y = [[args objectAtIndex:1] getRealValue];
    if (page.interpreter.currentPath == NULL) {
        [page.interpreter setCurrentPath:CGPathCreateMutable()];
    }
    CGPathMoveToPoint(page.interpreter.currentPath, NULL, x, y);
}

- (NSString*)compile {
    NSArray *args = [_cmdObj args];
    CGFloat x = [[args objectAtIndex:0] getRealValue];
    CGFloat y = [[args objectAtIndex:1] getRealValue];
    
    return [NSString stringWithFormat:@"%f %f m\n", x, y];
}
@end


@implementation GSOperator

+ (id)create {
    GSOperator *o = [[GSOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    if (page.interpreter.currentPath) {
        CGPathCloseSubpath(page.interpreter.currentPath);
    }
    
    CGContextBeginPath(context);
    CGContextAddPath(context, page.interpreter.currentPath);
    CGContextStrokePath(context);
    page.interpreter.currentPath = CGPathCreateMutable();
}

- (NSString*)compile {
    return @"S\n";
}
@end


@implementation GhOperator

+ (id)create {
    GhOperator *o = [[GhOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    if (page.interpreter.currentPath) {
        CGPathCloseSubpath(page.interpreter.currentPath);
    }
}

- (NSString*)compile {
    return @"h\n";
}
@end


@implementation GlOperator

+ (id)create {
    GlOperator *o = [[GlOperator alloc] init];
    return o;
}

- (void)eval:(CGContextRef)context page:(GPage*)page {
    NSArray *args = [_cmdObj args];
    CGFloat x = [[args objectAtIndex:0] getRealValue];
    CGFloat y = [[args objectAtIndex:1] getRealValue];

    CGPathAddLineToPoint(page.interpreter.currentPath, NULL, x, y);
}

- (NSString*)compile {
    NSArray *args = [_cmdObj args];
    CGFloat x = [[args objectAtIndex:0] getRealValue];
    CGFloat y = [[args objectAtIndex:1] getRealValue];
    
    return [NSString stringWithFormat:@"%f %f l\n", x, y];
}
@end
