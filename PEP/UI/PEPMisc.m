//
//  PEPMisc.m
//  PEP
//
//  Created by Aaron Elkins on 11/18/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPMisc.h"

NSArray *allFontsInSystem(void) {
    /*
     // This returns an array of NSStrings that gives you each font installed on the system
     NSArray *fonts = [[NSFontManager sharedFontManager] availableFontFamilies];

     // Does the same as the above, but includes each available font style (e.g. you get
     // Verdana, "Verdana-Bold", "Verdana-BoldItalic", and "Verdana-Italic" for Verdana).
     NSArray *fonts = [[NSFontManager sharedFontManager] availableFonts];
    */
    NSFontManager *fmg = [NSFontManager sharedFontManager];
    NSArray *families = [fmg availableFontFamilies];
    return families;
}
