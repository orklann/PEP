//
//  GInterpreter.m
//  PEP
//
//  Created by Aaron Elkins on 9/21/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GInterpreter.h"
#import "GObjects.h"
#import "GMisc.h"
#import "GPage.h"
#import "GGlyph.h"

BOOL isCommand(NSString *cmd, NSString *cmd2) {
    return [cmd isEqualToString:cmd2];
}

@implementation GInterpreter
+ (id)create {
    GInterpreter *o = [[GInterpreter alloc] init];
    return o;
}

- (void)setPage:(GPage*)p {
    page = p;
}

- (void)setParser:(GParser*)p {
    parser = p;
}

- (void)setInput:(NSData *)d {
    NSMutableData *data = [NSMutableData dataWithData:d];
    [data appendBytes:"\0" length:1];
    input = data;
}

- (CGFloat)drawString:(NSString*)ch font:(NSFont*)font context:(CGContextRef)context {
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:ch];
    [s addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, 1)];
    [s addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, 1)];
    
    CFAttributedStringRef attrStr = (__bridge CFAttributedStringRef)(s);
    CTLineRef line = CTLineCreateWithAttributedString(attrStr);
    CTLineDraw(line, context);
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    CTRunRef firstRun = CFArrayGetValueAtIndex(runs, 0);
    CGSize size;
    CTRunGetAdvances(firstRun, CFRangeMake(0, 1), &size);
    CFRelease(line);
    return size.width;
}

- (void)layoutStrings:(NSString*)s context:(CGContextRef)context  tj:(CGFloat)tjDelta{
    NSMutableArray *glyphs = [[page textParser] glyphs];
    NSFont *font = [page getCurrentFont];
    CGAffineTransform tm = [[page textState] textMatrix];
    CGFloat fs = [[page textState] fontSize];
    CGFloat h = 1.0; // we need this in graphics state
    CGFloat rise = [[page textState] rise];
    CGFloat cs = [[page textState] charSpace];
    CGFloat wc = [[page textState] wordSpace];
    CGAffineTransform trm = CGAffineTransformMake(fs*h, 0, 0, fs, 0, rise);
    CGAffineTransform rm = CGAffineTransformConcat(trm, tm);
    NSInteger i;
    CGFloat tj = tjDelta;
    for (i = 0; i < [s length]; i++) {
        NSString *ch = [s substringWithRange:NSMakeRange(i, 1)];
        CGContextSetTextMatrix(context, rm);
        CGFloat hAdvance = [self drawString:ch font:font context:context];
        
        //
        // Make glyphs for GTextParser
        //
        CGRect r = getGlyphBoundingBox(ch, font, [[page textState] textMatrix], hAdvance);
        
        // Test: draw bounding box for glyph
        //CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 0.5);
        //CGContextFillRect(context, r);
        
        // Apply current context matrix to get the right frame of glyph
        r = CGRectApplyAffineTransform(r, [[page graphicsState] ctm]);
        
        NSPoint p = CGContextGetTextPosition(context);
        // Apply current context matrix to get the right point for glyph
        p = CGPointApplyAffineTransform(p, [[page graphicsState] ctm]);
        
        GGlyph *glyph = [GGlyph create];
        [glyph setFrame:r];
        [glyph setPoint:p];
        [glyph setContent:ch];
        [glyphs addObject:glyph];
        
        // See "9.4.4 Text space details"
        CGFloat tx = ((hAdvance - (tj/1000.0)) * fs + cs + wc) * h;
        CGFloat ty = 0; // TODO: Handle vertical advance for vertical text layout
        CGAffineTransform tf = CGAffineTransformMake(1, 0, 0, 1, tx, ty);
        tm = CGAffineTransformConcat(tf, tm);
        [[page textState] setTextMatrix:tm];
        rm = CGAffineTransformConcat(trm, tm);
    }
}

- (void)parseCommands {
    commands = [NSMutableArray array];
    GParser *cmdParser = [GParser parser];
    [cmdParser setStream:input];
    id obj = [cmdParser parseNextObject];
    while([(GObject*)obj type] != kEndObject) {
        if ([(GObject*) obj type] == kCommandObject) {
            NSString *cmd = [(GCommandObject*)obj cmd];
            if (isCommand(cmd, @"Q")){ // Q
                // Do nothing
            } else if (isCommand(cmd, @"q")) { // q
                // Do nothing
            } else if (isCommand(cmd, @"re")) { // re
                NSArray *args = getCommandArgs(commands, 4);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"W")) { // W
                // Do nothing
            } else if (isCommand(cmd, @"n")) { // n
                // Do nothing
            } else if (isCommand(cmd, @"gs")) { // gs
                NSArray *args = getCommandArgs(commands, 1);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"cs")) { // cs
                NSArray *args = getCommandArgs(commands, 1);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"sc")) { // sc
                NSArray *args = getDynamicCommandArgs(commands);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"m")) { // m
                NSArray *args = getCommandArgs(commands, 2);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"l")) { // l
                NSArray *args = getCommandArgs(commands, 2);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"h") || isCommand(cmd, @"f")) { // h, f
                // Do nothing: No arguments
            } else if (isCommand(cmd, @"cm")) { // cm
                NSArray *args = getCommandArgs(commands, 6);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"BT")) { // BT
                // Do nothing
            } else if (isCommand(cmd, @"Tm")) { // Tm
                NSArray *args = getCommandArgs(commands, 6);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"Tf")) { // Tf
                NSArray *args = getCommandArgs(commands, 2);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"Tj")) { // Tj
                NSArray *args = getCommandArgs(commands, 1);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"ET")) { // ET
                // Do nothing
            } else if (isCommand(cmd, @"TJ")) { // TJ
                NSArray *args = getCommandArgs(commands, 1);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"Tc")) { // Tc
                NSArray *args = getCommandArgs(commands, 1);
                [(GCommandObject*)obj setArgs:args];
            }
            else {
                NSLog(@"GInterpreter:parseCommands not handle %@ operator", cmd);
            }
        }
        [commands addObject:obj];
        obj = [cmdParser parseNextObject];
    }
}

- (NSMutableArray*)commands {
    return commands;
}


- (void)eval_q_Command:(CGContextRef)context {
    CGContextSaveGState(context);
}

- (void)eval_Q_Command:(CGContextRef)context {
    CGContextRestoreGState(context);
}

- (void)eval_cm_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSArray *args = [cmdObj args];
    CGFloat a = [[args objectAtIndex:0] getRealValue];
    CGFloat b = [[args objectAtIndex:1] getRealValue];
    CGFloat c = [[args objectAtIndex:2] getRealValue];
    CGFloat d = [[args objectAtIndex:3] getRealValue];
    CGFloat e = [[args objectAtIndex:4] getRealValue];
    CGFloat f = [[args objectAtIndex:5] getRealValue];
    CGAffineTransform ctm = CGAffineTransformMake(a, b, c, d, e, f);
    [[page graphicsState] setCTM:ctm];
    CGContextConcatCTM(context, ctm);
}

- (void)eval_Tm_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSArray *args = [cmdObj args];
    CGFloat a = [[args objectAtIndex:0] getRealValue];
    CGFloat b = [[args objectAtIndex:1] getRealValue];
    CGFloat c = [[args objectAtIndex:2] getRealValue];
    CGFloat d = [[args objectAtIndex:3] getRealValue];
    CGFloat e = [[args objectAtIndex:4] getRealValue];
    CGFloat f = [[args objectAtIndex:5] getRealValue];
    CGAffineTransform tm = CGAffineTransformMake(a, b, c, d, e, f);
    [[page textState] setTextMatrix:tm];
    CGContextSetTextMatrix(context, tm);
}

- (void)eval_Tf_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSString *fontName = [(GNameObject*)[[cmdObj args] objectAtIndex:0] value];
    CGFloat fontSize = [[[cmdObj args] objectAtIndex:1] getRealValue];
    [[page textState] setFontName:fontName];
    [[page textState] setFontSize:fontSize];
  
    // Get font size in user space
    CGSize size = NSMakeSize(1.0, 1.0);
    CGAffineTransform tm = [[page textState] textMatrix];
    CGAffineTransform ctm  = [[page graphicsState] ctm];
    size = CGSizeApplyAffineTransform(size, tm);
    size = CGSizeApplyAffineTransform(size, ctm);
}

- (void)eval_Tj_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSString *string = [(GLiteralStringsObject*)[[cmdObj args] objectAtIndex:0]
                        value];
    [self layoutStrings:string context:context tj:0];
}

- (void)eval_TJ_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    GArrayObject *array = [[cmdObj args] objectAtIndex:0];
    NSUInteger i;
    CGFloat tjDelta = 0;
    for (i = 0; i < [[array value] count]; i++) {
        id a = [[array value] objectAtIndex:i];
        if ([(GObject*)a type] == kLiteralStringsObject) { // Literal strings
            [self layoutStrings:[(GLiteralStringsObject*)a value] context:context tj:tjDelta];
            tjDelta = 0;
        } else if ([(GObject*)a type] == kNumberObject) { // Number object for offset
            tjDelta = [(GNumberObject*)a getRealValue];
        }
    }
}

- (void)eval:(CGContextRef)context {
    [self parseCommands];
    NSUInteger i;
    for (i = 0; i < [commands count]; i++) {
        id obj = [commands objectAtIndex:i];
        if ([(GObject*)obj type] == kCommandObject) {
            GCommandObject *cmdObj = (GCommandObject*)obj;
            NSString *cmd = [cmdObj cmd];
            if (isCommand(cmd, @"Q")) { // eval Q
                [self eval_Q_Command:context];
            } else if (isCommand(cmd, @"q")) { // eval q
                [self eval_q_Command:context];
            } else if (isCommand(cmd, @"cm")) { // eval cm
                [self eval_cm_Command:context command:cmdObj];
            } else if (isCommand(cmd, @"Tm")) { // eval Tm
                [self eval_Tm_Command:context command:cmdObj];
            } else if (isCommand(cmd, @"Tf")) { // eval Tf
                [self eval_Tf_Command:context command:cmdObj];
            } else if (isCommand(cmd, @"TJ")) { // eval TJ
                [self eval_TJ_Command:context command:cmdObj];
            } else if (isCommand(cmd, @"Tj")) { // eval Tj
                [self eval_Tj_Command:context command:cmdObj];
            } else {
                NSLog(@"Operator %@ not eval.", cmd);
            }
        }
    }
}
@end
