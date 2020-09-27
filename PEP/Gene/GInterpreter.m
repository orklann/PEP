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
    NSLog(@"END parseCommands");
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
}

- (void)eval_Tj_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSFont *font = [page getCurrentFont];
    NSString *string = [(GLiteralStringsObject*)[[cmdObj args] objectAtIndex:0]
                        value];
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc]
                                    initWithString:string];
    [s addAttribute:NSFontAttributeName value:font
              range:NSMakeRange(0, [string length])];
    [s addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor]
              range:NSMakeRange(0, [string length])];
    
    CFAttributedStringRef attrStr = (__bridge CFAttributedStringRef)(s);
    CTLineRef line = CTLineCreateWithAttributedString(attrStr);
    CTLineDraw(line, context);
}

- (void)eval_TJ_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSFont *font = [page getCurrentFont];
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:@"P"];
    [s addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, 1)];
    [s addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, 1)];
    
    CFAttributedStringRef attrStr = (__bridge CFAttributedStringRef)(s);
    CTLineRef line = CTLineCreateWithAttributedString(attrStr);
    CTLineDraw(line, context);
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
            }
        }
    }
    NSLog(@"eval() %ld bytes in context: %@", [input length], context);
}
@end
