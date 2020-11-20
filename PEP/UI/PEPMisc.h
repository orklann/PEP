//
//  PEPMisc.h
//  PEP
//
//  Created by Aaron Elkins on 11/18/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN
// List all fonts in system
// Return a array of font names
NSArray *allFontFamiliesInSystem(void);
NSArray *allFontsInSystem(void);

// Get font path for a NSFont, use to get font styles by comparing the font name
// return by this method to fonts return by allFontsInSystem().
NSString *getFontPath(NSFont* font);

// Get font style based on font name
NSString *getFontStyleFromSubset(NSString* subsetName);
NSString *getFontNameFromSubset(NSString* subsetName);
NSString *getSubsetFontNameFromSubset(NSString* subsetName);
NS_ASSUME_NONNULL_END
