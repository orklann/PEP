//
//  GGlyph.m
//  PEP
//
//  Created by Aaron Elkins on 10/5/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GGlyph.h"
#import "GObjects.h"
#import "GMisc.h"
#import "GFontInfo.h"
#import "GPage.h"
#import "GDocument.h"

@implementation GGlyph
+ (id)create {
    GGlyph *g = [[GGlyph alloc] init];
    [g setDelta:0];
    [g setWordSpace:0];
    [g setCharacterSpace:0];
    [g setRise:0];
    return g;
}

- (void)setFrame:(NSRect)f {
    frame = f;
}

// return frame in GPage coordinate
// In some case, we need view coordinate, just call [GPage rectFromPageToView:]
// to convert to view coordinate
- (NSRect)frame {
    NSRect r = CGRectApplyAffineTransform(self.frameInGlyphSpace, self.textMatrix);
    // Apply current context matrix to get the right frame of glyph
    r = CGRectApplyAffineTransform(r, self.ctm);
    frame = r;
    NSRect cropBox = [_page cropBox];
    frame.origin.x -= cropBox.origin.x;
    frame.origin.y -= cropBox.origin.y;
    return frame;
}

- (void)setHeight:(CGFloat)h {
    height = h;
}

- (CGFloat)height {
    return [self frame].size.height;
}

- (void)setPoint:(NSPoint)p {
    point = p;
}

- (NSPoint)point {
    return point;
}

- (void)setContent:(NSString*)s {
    content = s;
}

- (NSString*)content {
    return content;
}

- (NSString*)literalString {
    NSString *ret;
    if ([content isEqualToString: @"("]) {
        ret = @"\\(";
    } else if ([content isEqualToString:@")"]) {
        ret = @"\\)";
    } else if ([content isEqualToString:@"\t"]) {
        ret = @"\\t";
    } else if ([content isEqualToString:@"\n"]) {
        ret = @"\\n";
    } else if ([content isEqualToString:@"\\"]) {
        ret = @"\\\\";
    } else {
        ret = content;
    }
    return ret;
}

- (NSString*)complieToOperators {
    NSMutableString *ret = [NSMutableString string];
    [ret appendString:@"\nQ q "];
    
    // Current context matrix (operator: cm)
    CGAffineTransform ctm = [self ctm];
    NSString *cm = [NSString stringWithFormat:@"%f %f %f %f %f %f cm ",
                    ctm.a, ctm.b, ctm.c, ctm.d, ctm.tx, ctm.ty];
    [ret appendString:cm];
    
    // Text Object
    [ret appendString:@"BT "];
    
    // Text matrix
    CGAffineTransform textMatrix = [self textMatrix];
    NSString *tm = [NSString stringWithFormat:@"%f %f %f %f %f %f Tm ",
                    textMatrix.a, textMatrix.b, textMatrix.c, textMatrix.d,
                    textMatrix.tx, textMatrix.ty];
    [ret appendString:tm];
    
    // Font
    // Use 1.0 font size, fontSize is always 1.0, we set it in GInterpreter
    [ret appendFormat:@"/%@ %f Tf ", [self fontName], [self fontSize]];
    
    // Tj
    [ret appendFormat:@"(%@) Tj ", [self literalString]];
    
    [ret appendString:@"ET \n"];
    
    return ret;
}

- (NSArray*)compileToCommands {
    NSMutableArray *commands = [NSMutableArray array];
    GCommandObject *cm = [self compileTocmCommand];
    GCommandObject *tm = [self compileToTmCommand];
    GCommandObject *tf = [self compileToTfComamnd];
    GCommandObject *tj = [self compileToTjCommand];
    [commands addObject:cm];
    [commands addObject:tm];
    [commands addObject:tf];
    [commands addObject:tj];
    return (NSArray*)commands;
}

- (GCommandObject*)compileTocmCommand {
    GCommandObject *cmCommand = [GCommandObject create];
    [cmCommand setCmd:@"cm"];
    CGAffineTransform ctm = [self ctm];
    GNumberObject *a = [GNumberObject create];
    [a setRealValue:ctm.a];
    GNumberObject *b = [GNumberObject create];
    [b setRealValue:ctm.b];
    GNumberObject *c = [GNumberObject create];
    [c setRealValue:ctm.c];
    GNumberObject *d = [GNumberObject create];
    [d setRealValue:ctm.d];
    GNumberObject *tx = [GNumberObject create];
    [tx setRealValue:ctm.tx];
    GNumberObject *ty = [GNumberObject create];
    [ty setRealValue:ctm.ty];
    NSArray *args = [NSArray arrayWithObjects:a, b, c, d, tx, ty, nil];
    [cmCommand setArgs:args];
    return cmCommand;
}

- (GCommandObject*)compileToTmCommand {
    GCommandObject *tmCommand = [GCommandObject create];
    [tmCommand setCmd:@"Tm"];
    CGAffineTransform tm = [self textMatrix];
    GNumberObject *a = [GNumberObject create];
    [a setRealValue:tm.a];
    GNumberObject *b = [GNumberObject create];
    [b setRealValue:tm.b];
    GNumberObject *c = [GNumberObject create];
    [c setRealValue:tm.c];
    GNumberObject *d = [GNumberObject create];
    [d setRealValue:tm.d];
    GNumberObject *tx = [GNumberObject create];
    [tx setRealValue:tm.tx];
    GNumberObject *ty = [GNumberObject create];
    [ty setRealValue:tm.ty];
    NSArray *args = [NSArray arrayWithObjects:a, b, c, d, tx, ty, nil];
    [tmCommand setArgs:args];
    return tmCommand;
}

- (GCommandObject*)compileToTfComamnd {
    GCommandObject *tfCommand = [GCommandObject create];
    [tfCommand setCmd:@"Tf"];
    GNameObject *fontName = [GNameObject create];
    [fontName setValue:[self fontName]];
    GNumberObject *fontSize = [GNumberObject create];
    [fontSize setRealValue:[self fontSize]];
    NSArray *args = [NSArray arrayWithObjects:fontName, fontSize, nil];
    [tfCommand setArgs:args];
    return tfCommand;
}

- (GCommandObject*)compileToTjCommand {
    GCommandObject *tjCommand = [GCommandObject create];
    [tjCommand setCmd:@"Tj"];
    GLiteralStringsObject *string = [GLiteralStringsObject create];
    [string setValue:[self content]];
    NSArray *args = [NSArray arrayWithObject:string];
    [tjCommand setArgs:args];
    return tjCommand;
}

- (void)updateGlyphWidth {
    CTFontRef coreFont = (__bridge CTFontRef)(self.font);
    char **encoding = [self encoding];
    CGGlyph a;
    CGFloat width = 0.0;
    unichar charCode = [content characterAtIndex:0];
    
    NSString *fontTag = self.fontName;
    NSString *fontKey = [self.page fontTagToFontKey:fontTag];
    GFontInfo *fontInfo = [self.page.doc.fontInfos objectForKey:fontKey];
    
    if (charCode > 255) {
        NSLog(@"Error: char code is greater than 255, it's not a latin character");
    }
    
    if (encoding != NULL) {
        char *glyphNameChars = encoding[charCode];
        NSString *glyphName = [NSString stringWithFormat:@"%s", glyphNameChars];
        a = CTFontGetGlyphWithName(coreFont, (__bridge CFStringRef)glyphName);
        
    } else {
        CTFontGetGlyphsForCharacters(coreFont, &charCode, &a, 1);
    }
    
    /* For type1 font program, we first get width from widths array */
    if ([[fontInfo subType] isEqualToString:@"Type1"]) {
        width = [fontInfo getCharWidth:charCode];
    } else {
        CGGlyph g[1];
        g[0] = a;
        // Get glyph width from font program
        width = CTFontGetAdvancesForGlyphs(coreFont, kCTFontOrientationHorizontal, g, NULL, 1);
    }
    
    // if width from CGGlyph is zero, we need to lookup it in fontInfos dictionary in GDocument
    if (width == 0.0) {
        width = [fontInfo getCharWidth:charCode];
    }
    
    self.widthInGlyphSpace = width;
    NSSize s = NSMakeSize(width, 0);
    s = CGSizeApplyAffineTransform(s, self.textMatrix);
    self.width = s.width;
}

- (void)updateGlyphFrame {
    CTFontRef coreFont = (__bridge CTFontRef)(self.font);
    CGFloat width = self.widthInGlyphSpace;
    CGFloat ascent = CTFontGetAscent(coreFont);
    CGFloat descent = CTFontGetDescent(coreFont);
    CGRect textRect = NSMakeRect(0, 0 - descent, width, descent + ascent);
    textRect = CGRectApplyAffineTransform(textRect, self.textMatrix);
    frame = CGRectApplyAffineTransform(textRect, self.ctm);
    NSRect cropBox = [_page cropBox];
    frame.origin.x -= cropBox.origin.x;
    frame.origin.y -= cropBox.origin.y;
    self.height = self.frame.size.height;
}

- (void)updateGlyphFrameInGlyphSpace {
    CTFontRef coreFont = (__bridge CTFontRef)(self.font);
    CGFloat width = self.widthInGlyphSpace;
    CGFloat ascent = CTFontGetAscent(coreFont);
    CGFloat descent = CTFontGetDescent(coreFont);
    self.frameInGlyphSpace = NSMakeRect(0, 0 - descent, width, descent + ascent);
}
@end
