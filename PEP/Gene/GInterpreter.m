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
#import "GEncodings.h"
#import "GDocument.h"
#import "GFontInfo.h"
#import "GFontEncoding.h"
#import "GTJText.h"

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

- (CGGlyph)getCGGlyphForGGlyph:(GGlyph*)glyph {
    CTFontRef coreFont = (__bridge CTFontRef)([glyph font]);
    char **encoding = [glyph encoding];
    GFontEncoding *fontEncoding = [glyph fontEncoding];
    CGGlyph ret = -1;
    unichar charCode = [[glyph content] characterAtIndex:0];
    if (charCode > 255) {
        NSLog(@"Error: char code is greater than 255, it's not a latin character");
    }
    
    NSString *glyphName = [fontEncoding getGlyphNameInDifferences:charCode];
    if (glyphName == nil && encoding != NULL) {
        char *glyphNameChars = encoding[charCode];
        glyphName = [NSString stringWithFormat:@"%s", glyphNameChars];
    }
    ret = CTFontGetGlyphWithName(coreFont, (__bridge CFStringRef)glyphName);
    // If glyph is ".notdef", we try to get glyph a from charcode instead.
    CFStringRef glyphName2 = CTFontCopyNameForGlyph(coreFont, ret);
    NSString *glyphNameNSString = (__bridge NSString *)glyphName2;
    if ([glyphNameNSString isEqualToString:@".notdef"]) {
        CTFontGetGlyphsForCharacters(coreFont, &charCode, &ret, 1);
    }

    return ret;
}

- (CGFloat)drawString:(NSString*)ch font:(NSFont*)font context:(CGContextRef)context {
    CTFontRef coreFont = (__bridge CTFontRef)(font);
    char **encoding = [[page textState] encoding];
    GFontEncoding *fontEncoding = [[page textState] fontEncoding];
    CGFloat width = 0.0;
    CGGlyph a;
    unichar charCode = [ch characterAtIndex:0];
    if (charCode > 255) {
        NSLog(@"Error: char code is greater than 255, it's not a latin character");
    }
    
    NSString *glyphName = [fontEncoding getGlyphNameInDifferences:charCode];
    if (glyphName == nil && encoding != NULL) {
        char *glyphNameChars = encoding[charCode];
        glyphName = [NSString stringWithFormat:@"%s", glyphNameChars];
    }
    
    a = CTFontGetGlyphWithName(coreFont, (__bridge CFStringRef)glyphName);
    
    // If glyph is ".notdef", we try to get glyph from charcode instead.
    CFStringRef glyphName2 = CTFontCopyNameForGlyph(coreFont, a);
    NSString *glyphNameNSString = (__bridge NSString *)glyphName2;
    if ([glyphNameNSString isEqualToString:@".notdef"]) {
        CTFontGetGlyphsForCharacters(coreFont, &charCode, &a, 1);
    }

    CGGlyph g[1];
    CGPoint p[1];
    g[0] = a;
    p[0] = NSZeroPoint;
    CGContextSetFillColorWithColor(context, [[NSColor blackColor] CGColor]);
    CTFontDrawGlyphs(coreFont, g, p, 1, context);
    
    // Get glyph width
    width = CTFontGetAdvancesForGlyphs(coreFont, kCTFontOrientationHorizontal, g, NULL, 1);
    
    // if width from CGGlyph is zero, we need to lookup it in fontInfos dictionary in GDocument
    if (width == 0.0) {
        NSString *fontTag = [[page textState] fontName];
        GFontInfo *fontInfo = [page.doc.fontInfos objectForKey:fontTag];
        width = [fontInfo getCharWidth:charCode];
    }
    //Debug:
    //NSLog(@"Debug: font: %@ %c width: %f char code:%d", [[page textState] fontName], charCode, width, charCode);
    return width;
}

- (void)drawGlyph:(GGlyph*)glyph context:(CGContextRef)context {
    CTFontRef coreFont = (__bridge CTFontRef)([glyph font]);
    CGGlyph g[1];
    CGPoint p[1];
    g[0] = [glyph glyph];
    p[0] = NSZeroPoint;
    CGContextSetFillColorWithColor(context, [[NSColor blackColor] CGColor]);
    CTFontDrawGlyphs(coreFont, g, p, 1, context);
}

// Return new created glyphs
- (NSMutableArray*)layoutStrings:(NSString*)s context:(CGContextRef)context  tj:(CGFloat)tjDelta prevTj:(int)prevTj{
    NSMutableArray *newCreatedGlyphs = [NSMutableArray array];
    NSMutableArray *glyphs = [[page textParser] glyphs];
    
    /*
     * TODO: Get rid of parameter (s)
     */
    NSFont *font = [page getCurrentFont:s];
    CGAffineTransform tm = [[page textState] textMatrix];
    CGFloat fs = [[page textState] fontSize];
    CGFloat h = 1.0; // we need this in graphics state
    CGFloat rise = [[page textState] rise];
    CGFloat cs = [[page textState] charSpace];
    CGFloat currentCharacterSpace = [[page textState] charSpace];
    // wordspace only apply to 0x32 (space) charater, see below for check this
    CGFloat wc = 0; // by default is 0 for none space characters (0x32)
    CGFloat currentWordspace = [[page textState] wordSpace];
    CGAffineTransform trm = CGAffineTransformMake(fs*h, 0, 0, fs, 0, rise);
    CGAffineTransform rm = CGAffineTransformConcat(trm, tm);
    NSInteger i;
    CGFloat tj = 0.0;
    for (i = 0; i < [s length]; i++) {
        NSString *ch = [s substringWithRange:NSMakeRange(i, 1)];
        if ([ch isEqualToString:@" "]) {
            wc = [[page textState] wordSpace];
        } else {
            wc = 0;
        }
        // Add glyph chars for font in GPage
        [page addGlyph:ch font:[[page textState] fontName]];
        
        CGContextSetTextMatrix(context, rm);
        CGFloat hAdvance = [self drawString:ch font:font context:context];
        
        
        if ([page needUpdate]) {
            //
            // Make glyphs for GTextParser
            //
            
            NSPoint p = CGContextGetTextPosition(context);
            // Apply current context matrix to get the right point for glyph
            p = CGPointApplyAffineTransform(p, [[page graphicsState] ctm]);
            
            GGlyph *glyph = [GGlyph create];
            
            [glyph setPage:page];
            [glyph setPoint:p];
            [glyph setContent:ch];
            [glyph setCtm:[[page graphicsState] ctm]];
            [glyph setTextMatrix:rm];
            [glyph setTextMatrixForRendering:rm];
            NSString *fontName = [[page textState] fontName];
            [glyph setFontName:fontName];
            [glyph setFont:font];
            
            // Use font size 1.0, we set font size in text matrix already,
            // We set the literal font size in fs below
            //[glyph setFontSize:[[page textState] fontSize]];
            [glyph setFontSize:1.0];
            
            // Set current word space
            [glyph setWordSpace:currentWordspace];
            
            // Set current character space
            [glyph setCharacterSpace:currentCharacterSpace];
            
            // Set rise
            [glyph setRise:rise];
            
            // Set literal font size
            [glyph setFs:fs];
            
            // Set current encoding
            [glyph setEncoding:[[page textState] encoding]];
            
            // Set current font encoding
            [glyph setFontEncoding:[[page textState] fontEncoding]];
            
            // Set CGGlyph for GGGlyph
            CGGlyph g = [self getCGGlyphForGGlyph:glyph];
            [glyph setGlyph:g];

            [glyph updateGlyphFrame];
            [glyph updateGlyphFrameInGlyphSpace];
            
            // Only set delta to first glyph of a string
            if (i == 0) {
                [glyph setDelta:prevTj];
            }
            [glyphs addObject:glyph];
            [newCreatedGlyphs addObject:glyph];
        }
        
        // Fixed: Right side of text not align
        // Only apply next offset after drawing last glyph
        if (i == [s length] - 1) {
            tj = tjDelta;
        }
        // See "9.4.4 Text space details"
        CGFloat tx = ((hAdvance - (tj/1000.0)) * fs + cs + wc) * h;
        CGFloat ty = 0; // TODO: Handle vertical advance for vertical text layout
        CGAffineTransform tf = CGAffineTransformMake(1, 0, 0, 1, tx, ty);
        tm = CGAffineTransformConcat(tf, tm);
        [[page textState] setTextMatrix:tm];
        rm = CGAffineTransformConcat(trm, tm);
    }
    
    return newCreatedGlyphs;
}

- (NSMutableArray*)commands {
    NSMutableArray *commands = [page commands];
    return commands;
}

- (void)parseCommands {
    // Only parse command if page updates
    if (![page needUpdate]) {
        return ;
    }
    [page initCommands];
    NSMutableArray* commands = [self commands];
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
            } else if (isCommand(cmd, @"Tw")) { // Tw
                NSArray *args = getCommandArgs(commands, 1);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"Td")) { // Td
                NSArray *args = getCommandArgs(commands, 2);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"TL")) { // TL
                NSArray *args = getCommandArgs(commands, 1);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"T*")) { // T*
                // Do nothing
            } else if (isCommand(cmd, @"'")) { // '
                NSArray *args = getCommandArgs(commands, 1);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"TD")) { // TD
                NSArray *args = getCommandArgs(commands, 2);
                [(GCommandObject*)obj setArgs:args];
            } else {
                //NSLog(@"GInterpreter:parseCommands not handle %@ operator", cmd);
            }
        }
        [commands addObject:obj];
        obj = [cmdParser parseNextObject];
    }
}

- (void)eval_q_Command:(CGContextRef)context {
    CGContextSaveGState(context);
    [page saveGraphicsState];
}

- (void)eval_Q_Command:(CGContextRef)context {
    CGContextRestoreGState(context);
    [page restoreGraphicsState];
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
    CGAffineTransform currentCTM = [[page graphicsState] ctm];
    CGAffineTransform newCTM = CGAffineTransformConcat(currentCTM, ctm);
    [[page graphicsState] setCTM:newCTM];
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
    [[page textState] setLineMatrix:tm];
    CGContextSetTextMatrix(context, tm);
}

- (void)eval_Tf_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSString *fontName = [(GNameObject*)[[cmdObj args] objectAtIndex:0] value];
    CGFloat fontSize = [[[cmdObj args] objectAtIndex:1] getRealValue];
    [[page textState] setFontName:fontName];
    [[page textState] setFontSize:fontSize];
    
    GDocument *doc = (GDocument*)[page doc];
    GFontEncoding *fontEncoding = [[doc fontEncodings] objectForKey:fontName];
    NSString *encoding = [fontEncoding encoding];
    
    char **encodingPointer = NULL;
    if ([encoding isEqualToString:@"MacRomanEncoding"]) {
        encodingPointer = MacRomanEncoding;
    } else if ([encoding isEqualToString:@"WinAnsiEncoding"]) {
        encodingPointer = WinAnsiEncoding;
    } else if ([encoding isEqualToString:@"MacExpertEncoding"]) {
        encodingPointer = MacExpertEncoding;
    } else {
        encodingPointer = StandardEncoding;
    }
    
    [[page textState] setEncoding:encodingPointer];
    [[page textState] setFontEncoding:fontEncoding];
  
    // Get font size in user space
    CGSize size = NSMakeSize(1.0, 1.0);
    CGAffineTransform tm = [[page textState] textMatrix];
    CGAffineTransform ctm  = [[page graphicsState] ctm];
    size = CGSizeApplyAffineTransform(size, tm);
    size = CGSizeApplyAffineTransform(size, ctm);
}

- (void)eval_Tj_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSString *string;
    GObject *a = [[cmdObj args] objectAtIndex:0];
    if ([a type] == kLiteralStringsObject) {
        string = [(GLiteralStringsObject*)a value];
    } else if ([a type] == kHexStringsObject) {
        string = [(GHexStringsObject*)a stringValue];
    }
    NSMutableArray *glyphs = [self layoutStrings:string context:context tj:0 prevTj:0];
    GTJText *text = [GTJText create];
    [text addGlyphs:glyphs];
    [[[page textParser] tjTexts] addObject:text];
}

- (void)eval_Td_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    CGFloat tx = [[[cmdObj args] objectAtIndex:0] getRealValue];
    CGFloat ty = [[[cmdObj args] objectAtIndex:1] getRealValue];
    CGAffineTransform tm = [[page textState] lineMatrix];
    CGAffineTransform m = CGAffineTransformIdentity;
    m.tx = tx;
    m.ty = ty;
    tm = CGAffineTransformConcat(m, tm);
    [[page textState] setTextMatrix:tm];
    [[page textState] setLineMatrix:tm];
}

- (void)eval_TD_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    CGFloat tx = [[[cmdObj args] objectAtIndex:0] getRealValue];
    CGFloat ty = [[[cmdObj args] objectAtIndex:1] getRealValue];
    
    // Set leading in text state
    [[page textState] setLeading:ty * -1];
    
    // The same as Td operator
    CGAffineTransform tm = [[page textState] lineMatrix];
    CGAffineTransform m = CGAffineTransformIdentity;
    m.tx = tx;
    m.ty = ty;
    tm = CGAffineTransformConcat(m, tm);
    [[page textState] setTextMatrix:tm];
    [[page textState] setLineMatrix:tm];
}

- (void)eval_BT_Command:(CGContextRef)context command:(GCommandObject*)cmdObj  {
    [[page textState] setTextMatrix:CGAffineTransformIdentity];
    [[page textState] setLineMatrix:CGAffineTransformIdentity];
}


- (void)eval_TL_Command:(CGContextRef)context command:(GCommandObject*)cmdObj  {
    CGFloat tl = [[[cmdObj args] objectAtIndex:0] getRealValue];
    [[page textState] setLeading:tl];
}

- (void)eval_Tc_Command:(CGContextRef)context command:(GCommandObject*)cmdObj  {
    CGFloat tc = [[[cmdObj args] objectAtIndex:0] getRealValue];
    [[page textState] setCharSpace:tc];
}

- (void)eval_Tw_Command:(CGContextRef)context command:(GCommandObject*)cmdObj  {
    CGFloat tw = [[[cmdObj args] objectAtIndex:0] getRealValue];
    [[page textState] setWordSpace:tw];
}

- (void)eval_TStar_Command:(CGContextRef)context command:(GCommandObject*)cmdObj  {
    CGFloat tl = [[page textState] leading];
    tl = -1 * tl;
    
    CGAffineTransform tm = [[page textState] lineMatrix];
    CGAffineTransform m = CGAffineTransformIdentity;
    m.tx = 0;
    m.ty = tl;
    tm = CGAffineTransformConcat(m, tm);
    [[page textState] setTextMatrix:tm];
    [[page textState] setLineMatrix:tm];
}

- (void)eval_Single_Quote_Command:(CGContextRef)context command:(GCommandObject*)cmdObj  {
    // The same as T*
    CGFloat tl = [[page textState] leading];
    tl = -1 * tl;
    
    CGAffineTransform tm = [[page textState] lineMatrix];
    CGAffineTransform m = CGAffineTransformIdentity;
    m.tx = 0;
    m.ty = tl;
    tm = CGAffineTransformConcat(m, tm);
    [[page textState] setTextMatrix:tm];
    [[page textState] setLineMatrix:tm];
    
    // The same as Tj
    NSString *string;
    GObject *a = [[cmdObj args] objectAtIndex:0];
    if ([a type] == kLiteralStringsObject) {
        string = [(GLiteralStringsObject*)a value];
    } else if ([a type] == kHexStringsObject) {
        string = [(GHexStringsObject*)a stringValue];
    }
    [self layoutStrings:string context:context tj:0 prevTj:0];
}

- (void)eval_TJ_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    GArrayObject *array = [[cmdObj args] objectAtIndex:0];
    GTJText *text = [GTJText create];
    int i;
    CGFloat tjDelta = 0.0;
    int prevTj = 0;
    for (i = 0; i < [[array value] count]; i++) {
        id a = [[array value] objectAtIndex:i];
        if ([(GObject*)a type] == kLiteralStringsObject ||
            [(GObject*)a type] == kHexStringsObject) { // Literal strings
            if (i + 1 <= [[array value] count] - 1) {
                id nextObject = [[array value] objectAtIndex:i + 1];
                if ([(GObject*)nextObject type] == kNumberObject) { // Next object is offset
                    tjDelta = [(GNumberObject*)nextObject getRealValue];
                }
            }
            
            if (i - 1 >= 0) {
                id prevObject = [[array value] objectAtIndex:i - 1];
                if ([(GObject*)prevObject type] == kNumberObject) { // Prev object is offset
                    prevTj = (int)[(GNumberObject*)prevObject getRealValue];
                } else {
                    prevTj = 0;
                }
            }
            
            NSString *string;
            if ([(GObject*)a type] == kLiteralStringsObject) {
                string = [(GLiteralStringsObject*)a value];
            } else if ([(GObject*)a type] == kHexStringsObject) {
                string = [(GHexStringsObject*)a stringValue];
            }
            NSMutableArray *glyphs = [self layoutStrings:string context:context tj:tjDelta prevTj:prevTj];
            [text addGlyphs:glyphs];
            tjDelta = 0.0;
        }
    }
    [[[page textParser] tjTexts] addObject:text];
}

- (void)eval:(CGContextRef)context {
    //NSDate *methodStart = [NSDate date];
    if ([page needUpdate]) {
        [self parseCommands];
        NSMutableArray *commands = [self commands];
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
                } else if (isCommand(cmd, @"Td")) { // eval Td
                    [self eval_Td_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"TL")) { // eval TL
                    [self eval_TL_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"T*")) { // eval T*
                    [self eval_TStar_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"'")) { // eval '
                    [self eval_Single_Quote_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"BT")) { // eval BT
                    [self eval_BT_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"TD")) { // eval TD
                    [self eval_TD_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"Tc")) { // eval Tc
                    [self eval_Tc_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"Tw")) { // eval Tw
                    [self eval_Tw_Command:context command:cmdObj];
                } else {
                    //NSLog(@"Operator %@ not eval.", cmd);
                }
            }
        }
    } else {
        [self drawAllGlyphs:context];
    }
    
    /* Measure time */
/*
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"Debug: eval() executionTime = %f", executionTime);
*/
}

- (void)drawAllGlyphs:(CGContextRef)context {
    CGContextSaveGState(context); // q
    for (GGlyph * glyph in [[page textParser] glyphs]) {
        [self drawGlyph:glyph inContext:context];
    }
    CGContextRestoreGState(context); // Q
}

- (void)drawGlyph:(GGlyph*)glyph inContext:(CGContextRef)context {
    
    if (!CGAffineTransformEqualToTransform(CGContextGetCTM(context), [glyph ctm])) {
        CGContextRestoreGState(context); // Q
        CGContextSaveGState(context); // q
        CGContextConcatCTM(context, [glyph ctm]);
    }
    
    CGContextSetTextMatrix(context, [glyph textMatrixForRendering]);
    [self drawGlyph:glyph context:context];
}
@end
