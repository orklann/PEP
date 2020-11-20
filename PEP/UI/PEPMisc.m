//
//  PEPMisc.m
//  PEP
//
//  Created by Aaron Elkins on 11/18/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPMisc.h"

NSArray *allFontFamiliesInSystem(void) {
    /*
     This returns an array of NSStrings that gives you each font installed on the system
    */
    NSFontManager *fmg = [NSFontManager sharedFontManager];
    NSArray *families = [fmg availableFontFamilies];
    return families;
}

NSArray *allFontsInSystem(void) {
    /*
     Does the same to allFontFamiliesInSystem(), but includes each available font style (e.g. you get
     Verdana, "Verdana-Bold", "Verdana-BoldItalic", and "Verdana-Italic" for Verdana).
    */
    NSFontManager *fmg = [NSFontManager sharedFontManager];
    NSArray *families = [fmg availableFonts];
    return families;
}

NSString *getFontPath(NSFont* font) {
    CTFontDescriptorRef ctFontRef = CTFontDescriptorCreateWithNameAndSize ((CFStringRef)[font fontName], [font pointSize]);
    NSFontDescriptor* fontRef = (__bridge NSFontDescriptor*)ctFontRef;
    CFURLRef url = (CFURLRef)CTFontDescriptorCopyAttribute((CTFontDescriptorRef)fontRef, kCTFontURLAttribute);
    NSString *fontPath = [NSString stringWithString:[(NSURL *)CFBridgingRelease(url) path]];
    CFRelease(ctFontRef);
    return fontPath;
}

NSString *getFontStyle(NSString* fontName) {
    NSMutableString *result = [NSMutableString string];
    int i;
    for (i = (int)[fontName length] - 1; i >= 0; i--) {
        if ([fontName characterAtIndex:i] != '-') {
            [result appendString:[fontName substringWithRange:NSMakeRange(i, 1)]];
        } else {
            break;
        }
    }
    
    NSMutableString *reversed = [NSMutableString string];
    for (i = (int)[result length] - 1;  i >= 0; i--) {
        [reversed appendString:[result substringWithRange:NSMakeRange(i, 1)]];
    }
    
    return reversed;
}
