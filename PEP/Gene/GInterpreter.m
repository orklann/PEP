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
#import "GColorSpace.h"
#import "GOperators.h"

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
    
    NSString *glyphName;
    if (fontEncoding) {
        glyphName = [fontEncoding getGlyphNameInDifferences:charCode];
    }

    if (glyphName == nil && encoding != NULL) {
        char *glyphNameChars = encoding[charCode];
        glyphName = [NSString stringWithFormat:@"%s", glyphNameChars];
    }
    ret = CTFontGetGlyphWithName(coreFont, (__bridge CFStringRef)glyphName);
    // If glyph is ".notdef", we try to get glyph a from charcode instead.
    CFStringRef glyphName2 = CTFontCopyNameForGlyph(coreFont, ret);
    NSString *glyphNameNSString = (__bridge NSString *)glyphName2;
    if (glyphNameNSString == nil || [glyphNameNSString isEqualToString:@".notdef"]) {
        CTFontGetGlyphsForCharacters(coreFont, &charCode, &ret, 1);
    }
    
    CFStringRef glyphName3 = CTFontCopyNameForGlyph(coreFont, ret);
    glyphNameNSString = (__bridge NSString *)glyphName3;

    return ret;
}


- (CGFloat)drawString:(NSString*)ch font:(NSFont*)font context:(CGContextRef)context {
    CTFontRef coreFont = (__bridge CTFontRef)(font);
    char **encoding = [[page textState] encoding];
    GFontEncoding *fontEncoding = [[page textState] fontEncoding];
    CGFloat width = 0.0;
    CGGlyph a;
    unichar charCode = [ch characterAtIndex:0];
    
    NSString *fontTag = [[page textState] fontName];
    NSString *fontKey = [page fontTagToFontKey:fontTag];
    GFontInfo *fontInfo = [page.doc.fontInfos objectForKey:fontKey];
    
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
    
    if (![page prewarm]) {
        // Set nonstorking color from graphic state for context
        NSColor * nonStrokeColor = [page.graphicsState nonStrokeColor];
        CGContextSetFillColorWithColor(context, [nonStrokeColor CGColor]);
        CTFontDrawGlyphs(coreFont, g, p, 1, context);
    }
    
    /* For type1 font program, we first get width from widths array */
    if ([[fontInfo subType] isEqualToString:@"Type1"]) {
        width = [fontInfo getCharWidth:charCode];
    } else {
        // Get glyph width from font program
        width = CTFontGetAdvancesForGlyphs(coreFont, kCTFontOrientationHorizontal, g, NULL, 1);
    }
    
    // if width from CGGlyph is zero, we need to lookup it in fontInfos dictionary in GDocument
    if (width == 0.0) {
        width = [fontInfo getCharWidth:charCode];
    }
    return width;
}

- (void)drawGlyph:(GGlyph*)glyph context:(CGContextRef)context {
    CTFontRef coreFont = (__bridge CTFontRef)([glyph font]);
    CGGlyph g[1];
    CGPoint p[1];
    g[0] = [glyph glyph];
    p[0] = NSZeroPoint;
    NSColor *textColor = [glyph textColor];
    CGContextSetFillColorWithColor(context, [textColor CGColor]);
    CTFontDrawGlyphs(coreFont, g, p, 1, context);
}

// Return new created glyphs
- (NSMutableArray*)layoutStrings:(NSString*)s context:(CGContextRef)context  tj:(CGFloat)tjDelta prevTj:(CGFloat)prevTj{
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
        
        if (![page prewarm]) {
            CGContextSetTextMatrix(context, rm);
        }
        CGFloat hAdvance = [self drawString:ch font:font context:context];
        
        
        if ([page needUpdate]) {
            //
            // Make glyphs for GTextParser
            //
            NSPoint p = NSZeroPoint;
            if (![page prewarm]) {
                p = CGContextGetTextPosition(context);
                // Apply current context matrix to get the right point for glyph
                p = CGPointApplyAffineTransform(p, [[page graphicsState] ctm]);
            }
            
            GGlyph *glyph = [GGlyph create];
            
            [glyph setPage:page];
            [glyph setPoint:p];
            [glyph setContent:ch];
            [glyph setCtm:[[page graphicsState] ctm]];
            [glyph setTextMatrix:rm];
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
            
            // Set text color
            [glyph setTextColor:[page.graphicsState nonStrokeColor]];
            
            // Set CGGlyph for GGGlyph
            CGGlyph g = [self getCGGlyphForGGlyph:glyph];
            [glyph setGlyph:g];

            [glyph updateGlyphWidth];
            [glyph updateGlyphFrame];
            [glyph updateGlyphFrameInGlyphSpace];
            
            // Only set delta to first glyph of a string
            if (i == 0) {
                [glyph setDelta:prevTj];
            }
            
            [glyphs addObject:glyph];
            [page.graphicElements addObject:glyph];
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
            } else if (isCommand(cmd, @"h")) { // h
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
            } else if (isCommand(cmd, @"g")) { // g
                NSArray *args = getCommandArgs(commands, 1);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"G")) { // G
                NSArray *args = getCommandArgs(commands, 1);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"f*")) { // f*
                // Do nothing, no arguments
            } else if (isCommand(cmd, @"f")) { // f
                // Do nothing, no arguments
            } else if (isCommand(cmd, @"W*")) { // W*
                // Do nothing, no arguments
            } else if (isCommand(cmd, @"W")) { // W
                // Do nothing, no arguments
            } else if (isCommand(cmd, @"n")) { // n
                // Do nothing, no arguments
            } else if (isCommand(cmd, @"scn")) { // scn
                NSArray *args = getDynamicCommandArgs(commands);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"S")) { // S
                // Do nothing, no arguments
            } else if (isCommand(cmd, @"w")) { // w
                NSArray *args = getCommandArgs(commands, 1);
                [(GCommandObject*)obj setArgs:args];
            } else if (isCommand(cmd, @"c")) { // c
                NSArray *args = getCommandArgs(commands, 6);
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
    if (![page prewarm]) {
        CGContextSaveGState(context);
    }
    [page saveGraphicsState];
    
    GqOperator *op = [GqOperator create];
    [page.graphicElements addObject:op];
}

- (void)eval_Q_Command:(CGContextRef)context {
    if (![page prewarm]) {
        CGContextRestoreGState(context);
    }
    [page restoreGraphicsState];
    GQOperator *op = [GQOperator create];
    [page.graphicElements addObject:op];
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
    if (![page prewarm]) {
        CGContextConcatCTM(context, ctm);
    }
    
    GcmOperator *op = [GcmOperator create];
    [op setCmdObj:cmdObj];
    [page.graphicElements addObject:op];
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
    if (![page prewarm]) {
        CGContextSetTextMatrix(context, tm);
    }
}

- (void)eval_Tf_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSString *fontName = [(GNameObject*)[[cmdObj args] objectAtIndex:0] value];
    CGFloat fontSize = [[[cmdObj args] objectAtIndex:1] getRealValue];
    [[page textState] setFontName:fontName];
    [[page textState] setFontSize:fontSize];
    
    GDocument *doc = (GDocument*)[page doc];
    NSString *fontKey = [page fontTagToFontKey:fontName];
    GFontEncoding *fontEncoding = [[doc fontEncodings] objectForKey:fontKey];
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
    CGFloat prevTj = 0.0;
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
                    prevTj = [(GNumberObject*)prevObject getRealValue];
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

- (void)eval_g_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    GgOperator *op = [GgOperator create];
    [op setCmdObj:[cmdObj clone]];
    [page.graphicElements addObject:op];
    
    // Set color space in graphic state
    GColorSpace *cs = [GColorSpace colorSpaceWithName:@"DeviceGray" page:page];
    [page.graphicsState setNonStrokeColorSpace:cs];
    
    // Set nonStrokeColor in graphic state
    NSColor *nonStrokeColor = [cs mapColor:cmdObj];
    [page.graphicsState setNonStrokeColor:nonStrokeColor];
    
    // Also set fill color (nonStrokeColor) for context
    if (![page prewarm]) {
        CGContextSetFillColorWithColor(context, [nonStrokeColor CGColor]);
    }
}

- (void)eval_G_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    GGOperator *op = [GGOperator create];
    [op setCmdObj:[cmdObj clone]];
    [page.graphicElements addObject:op];
    
    // Set color space in graphic state
    GColorSpace *cs = [GColorSpace colorSpaceWithName:@"DeviceGray" page:page];
    [page.graphicsState setStrokeColorSpace:cs];
    
    // Set strokeColor in graphic state
    NSColor *strokeColor = [cs mapColor:cmdObj];
    [page.graphicsState setStrokeColor:strokeColor];
    
    // Also set stroke color (strokeColor) for context
    if (![page prewarm]) {
        CGContextSetStrokeColorWithColor(context, [strokeColor CGColor]);
    }
}

- (void)eval_re_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSArray *args = [cmdObj args];
    CGFloat x = [[args objectAtIndex:0] getRealValue];
    CGFloat y = [[args objectAtIndex:1] getRealValue];
    CGFloat w = [[args objectAtIndex:2] getRealValue];
    CGFloat h = [[args objectAtIndex:3] getRealValue];
    NSRect rect = NSMakeRect(x, y, w, h);
    
    // Turn negative size of rect into positive size
    rect = CGRectStandardize(rect);
    _currentPath = CGPathCreateMutable();
    CGPathAddRect(_currentPath, NULL, rect);
    
    GreOperator *op = [GreOperator create];
    [op setCmdObj:cmdObj];
    [page.graphicElements addObject:op];
}

- (void)eval_fStar_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    if ([[page graphicsState] overprintNonstroking]) {
        return ;
    }
    
    if (![page prewarm]) {
        CGContextBeginPath(context);
        CGContextAddPath(context, _currentPath);
        NSColor *nonStrokeColor = [page.graphicsState nonStrokeColor];
        CGContextSetFillColorWithColor(context, [nonStrokeColor CGColor]);
        CGContextEOFillPath(context);
        _currentPath = CGPathCreateMutable();
    }
    
    GfStarOperator *op = [GfStarOperator create];
    [page.graphicElements addObject:op];
}

- (void)eval_f_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    if ([[page graphicsState] overprintNonstroking]) {
        return ;
    }
    
    if (![page prewarm]) {
        CGContextBeginPath(context);
        CGContextAddPath(context, _currentPath);
        NSColor *nonStrokeColor = [page.graphicsState nonStrokeColor];
        CGContextSetFillColorWithColor(context, [nonStrokeColor CGColor]);
        CGContextFillPath(context);
        /*
         * NOTE: All painting operator should set current path to undefined after painting.
         *       See 8.5.2.1 General
         */
        _currentPath = CGPathCreateMutable();
    }
    
    GfOperator *op = [GfOperator create];
    [page.graphicElements addObject:op];
}

- (void)eval_WStar_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    if (![page prewarm]) {
        CGContextBeginPath(context);
        CGContextAddPath(context, _currentPath);
        CGContextEOClip(context);
    }
    
    GWStarOperator *op = [GWStarOperator create];
    [page.graphicElements addObject:op];
}

- (void)eval_W_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    if (![page prewarm]) {
        CGContextBeginPath(context);
        CGContextAddPath(context, _currentPath);
        CGContextClip(context);
    }
    
    GWOperator *op = [GWOperator create];
    [page.graphicElements addObject:op];
}

- (void)eval_n_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    // We don't need to eval `n` operator, since it is usually used in the way of: W*,
    // n or W, n
    // And what n does is what W*, W does
    // See 8.5.4 Clipping path operators
    /*
     * We need to add n operator to graphicElements
     */
    GnOperator *op = [GnOperator create];
    [page.graphicElements addObject:op];
    
    /*
     * And finally, as a path-painting operator, we need to set the current
     * path to undefined.
     */
    _currentPath = CGPathCreateMutable();
}


- (void)eval_cs_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSArray *args = [cmdObj args];
    NSString *csName = [(GNameObject*)[args firstObject] value];

    // Set color space in graphic state for non stroke color space
    GColorSpace *cs = [GColorSpace colorSpaceWithName:csName page:page];
    [page.graphicsState setNonStrokeColorSpace:cs];
    
    GcsOperator *op = [GcsOperator create];
    [op setColorSpaceName:csName];
    [page.graphicElements addObject:op];
}

- (void)eval_scn_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    GscnOperator *op = [GscnOperator create];
    // Why clone? Because mapColor: will modify args in GCommandObject
    [op setCmdObj:[cmdObj clone]];
    [page.graphicElements addObject:op];
    
    GColorSpace *cs = [page.graphicsState nonStrokeColorSpace];
    
    // Set nonStrokeColor in graphic state
    NSColor *nonStrokeColor = [cs mapColor:cmdObj];
    [page.graphicsState setNonStrokeColor:nonStrokeColor];
    
    // Also set fill color (nonStrokeColor) for context
    if (![page prewarm]) {
        CGContextSetFillColorWithColor(context, [nonStrokeColor CGColor]);
    }
}

- (void)eval_m_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSArray *args = [cmdObj args];
    CGFloat x = [[args objectAtIndex:0] getRealValue];
    CGFloat y = [[args objectAtIndex:1] getRealValue];
    if (_currentPath == NULL) {
        _currentPath = CGPathCreateMutable();
    }
    CGPathMoveToPoint(_currentPath, NULL, x, y);
    
    GmOperator *op = [GmOperator create];
    [op setCmdObj:cmdObj];
    [page.graphicElements addObject:op];
}

- (void)eval_S_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    if (_currentPath) {
        CGPathCloseSubpath(_currentPath);
    }
    
    if (![page prewarm]) {
        CGContextBeginPath(context);
        CGContextAddPath(context, _currentPath);
        CGContextSetLineWidth(context, [page.graphicsState lineWidth]);
        CGContextSetStrokeColorWithColor(context, [[page.graphicsState strokeColor] CGColor]);
        CGContextStrokePath(context);
        _currentPath = CGPathCreateMutable();
    }
    
    GSOperator *op = [GSOperator create];
    [page.graphicElements addObject:op];
}

- (void)eval_h_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    if (_currentPath) {
        CGPathCloseSubpath(_currentPath);
    }
    
    GhOperator *op = [GhOperator create];
    [page.graphicElements addObject:op];
}

- (void)eval_gs_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSArray *args = [cmdObj args];
    GNameObject *gs = [args firstObject];
    NSString *gsName = [gs value];
 
    GDictionaryObject *extGStateDict = [[page.resources value]
                                        objectForKey:@"ExtGState"];
    
    if ([extGStateDict type] == kRefObject) {
        extGStateDict = [page.parser getObjectByRef:[(GRefObject*)extGStateDict getRefString]];
    }
    
    GDictionaryObject *gsObject = [[extGStateDict value] objectForKey:gsName];
    
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
    
    // Add operator to page's graphicElements
    GgsOperator *opt = [GgsOperator create];
    [opt setGsName:gsName];
    [page.graphicElements addObject:opt];
}

- (void)eval_l_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSArray *args = [cmdObj args];
    CGFloat x = [[args objectAtIndex:0] getRealValue];
    CGFloat y = [[args objectAtIndex:1] getRealValue];
 
    CGPathAddLineToPoint(_currentPath, NULL, x, y);
    
    GlOperator *op = [GlOperator create];
    [op setCmdObj:cmdObj];
    [page.graphicElements addObject:op];
}

- (void)eval_w_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSArray *args = [cmdObj args];
    CGFloat lineWidth = [[args objectAtIndex:0] getRealValue];
    
    // Set line width in graphic state
    [page.graphicsState setLineWidth:lineWidth];
    
    GwOperator *op = [GwOperator create];
    [op setCmdObj:[cmdObj clone]];
    [page.graphicElements addObject:op];
}

- (void)eval_c_Command:(CGContextRef)context command:(GCommandObject*)cmdObj {
    NSArray *args = [cmdObj args];
    CGFloat x1 = [[args objectAtIndex:0] getRealValue];
    CGFloat y1 = [[args objectAtIndex:1] getRealValue];
    CGFloat x2 = [[args objectAtIndex:2] getRealValue];
    CGFloat y2 = [[args objectAtIndex:3] getRealValue];
    CGFloat x3 = [[args objectAtIndex:4] getRealValue];
    CGFloat y3 = [[args objectAtIndex:5] getRealValue];
 
    CGPathAddCurveToPoint(_currentPath, NULL, x1, y1, x2, y2, x3, y3);
    

    GcOperator *op = [GcOperator create];
    [op setCmdObj:cmdObj];
    [page.graphicElements addObject:op];
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
                } else if (isCommand(cmd, @"g")) { // eval g
                    [self eval_g_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"G")) { // eval G
                    [self eval_G_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"re")) { // eval re
                    [self eval_re_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"f*")) { // eval f*
                    [self eval_fStar_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"f")) { // eval f
                    [self eval_f_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"W*")) { // eval W*
                    [self eval_WStar_Command:context command:cmdObj];
                }  else if (isCommand(cmd, @"W")) { // eval W
                    [self eval_W_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"n")) { // eval n
                    [self eval_n_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"cs")) { // eval cs
                    [self eval_cs_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"scn")) { // eval scn
                    [self eval_scn_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"m")) { // eval m
                    [self eval_m_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"S")) { // eval S
                    [self eval_S_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"h")) { // eval h
                    [self eval_h_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"gs")) { // eval gs
                    [self eval_gs_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"l")) { // eval l
                    [self eval_l_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"w")) { // eval w
                    [self eval_w_Command:context command:cmdObj];
                } else if (isCommand(cmd, @"c")) { // eval c
                    [self eval_c_Command:context command:cmdObj];
                } else {
                    //NSLog(@"Operator %@ not eval.", cmd);
                }
            }
        }
    } else {
        [self evalGraphicElements:context];
    }
    
    /* Measure time */
/*
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"Debug: eval() executionTime = %f", executionTime);
*/
}

- (void)evalGraphicElements:(CGContextRef)context {
    if (page.prewarm) {
        return ;
    }
    
    CGContextSaveGState(context); // q
    for (id ele in page.graphicElements) {
        if ([[ele className] isEqualToString:@"GGlyph"]) {
            GGlyph *glyph = (GGlyph*)ele;
            [self drawGlyph:glyph inContext:context];
        } else {
            [ele eval:context page:page];
        }
    }
    CGContextRestoreGState(context); // Q
}

- (void)drawGlyph:(GGlyph*)glyph inContext:(CGContextRef)context {
    
    //if (!CGAffineTransformEqualToTransform(CGContextGetCTM(context), [glyph ctm])) {
    //    CGContextRestoreGState(context); // Q
    //    CGContextSaveGState(context); // q
        CGContextConcatCTM(context, [glyph ctm]);
    //}
    
    CGContextSetTextMatrix(context, [glyph textMatrix]);
    [self drawGlyph:glyph context:context];
}
@end
