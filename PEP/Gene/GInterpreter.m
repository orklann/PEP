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

BOOL isCommand(NSString *cmd, NSString *cmd2) {
    return [cmd isEqualToString:cmd2];
}

@implementation GInterpreter
+ (id)create {
    GInterpreter *o = [[GInterpreter alloc] init];
    return o;
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

- (void)eval:(CGContextRef)context {
    [self parseCommands];
    NSLog(@"eval() %ld bytes in context: %@", [input length], context);
}
@end