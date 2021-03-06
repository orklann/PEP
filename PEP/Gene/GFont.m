//
//  GFont.m
//  PEP
//
//  Created by Aaron Elkins on 9/24/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GFont.h"
#import "GPage.h"

@implementation GFont
+ (id)fontWithName:(NSString*)name page:(GPage*)p {
    GFont *f = [[GFont alloc] init];
    [f setEmbededFont:YES];
    [f setPage:p];
    [f setFontName:name];
    [f parseFontData];
    return f;
}

- (void)setEmbededFont:(BOOL)v {
    embededFont = v;
}

- (void)setFontName:(NSString*)name {
    fontName = name;
}

- (void)setPage:(GPage*)p {
    page = p;
}

- (void)parseFontData {
    GParser *parser = [page parser];
    GDictionaryObject *res = [page resources];
    GDictionaryObject *fonts;
    id fontDict = [[res value] objectForKey:@"Font"];
    if ([(GObject*)fontDict type] == kRefObject) {
        fonts = [parser getObjectByRef:[fontDict getRefString]];
    } else if ([(GObject*)fontDict type] == kDictionaryObject){
        fonts = fontDict;
    }
    
    GRefObject *ref = [[fonts value] objectForKey:fontName];
    GDictionaryObject *font = [parser getObjectByRef:[ref getRefString]];
    
    // For /Type0 /Subtype font
    GNameObject *subType = [[font value] objectForKey:@"Subtype"];
    if ([[subType value] isEqualToString:@"Type0"]) {
        GArrayObject *decendantFonts = [[font value] objectForKey:@"DescendantFonts"];
        GRefObject *firstFontRef = [[decendantFonts value] firstObject];
        font = [parser getObjectByRef:[firstFontRef getRefString]];
    }
    
    ref = [[font value] objectForKey:@"FontDescriptor"];
    // Not font descriptor found, just use `BaseFont`, and this font should be
    // not a embedded font.
    if (ref == nil) {
        embededFont = NO;
        GNameObject *baseFont = [[font value] objectForKey:@"BaseFont"];
        noneEmbeddedFontName = [baseFont value];
        return ;
    }
    GDictionaryObject *descriptor = [parser getObjectByRef:[ref getRefString]];
    
    // Check if font is embedded font, if not embeded, just return and set embededFont to NO
    if ([[descriptor value] objectForKey:@"FontFile"] == nil &&
        [[descriptor value] objectForKey:@"FontFile2"] == nil &&
        [[descriptor value] objectForKey:@"FontFile3"] == nil) {
        embededFont = NO;
        GLiteralStringsObject *fontFamily = [[descriptor value] objectForKey:@"FontFamily"];
        if (fontFamily != nil) {
            noneEmbeddedFontName = [fontFamily value];
        } else {
            GLiteralStringsObject *fontName = [[descriptor value] objectForKey:@"FontName"];
            noneEmbeddedFontName = [fontName value];
        }
        return ;
    }
    
    // Only get font program for `/FontFile2` for truetype font
    // Other fonts will be in `/FontFile`, `/FontFile3`, we will handle it later
    id fontFile = [[descriptor value] objectForKey:@"FontFile"];
    id fontFile2 = [[descriptor value] objectForKey:@"FontFile2"];
    id fontFile3 = [[descriptor value] objectForKey:@"FontFile3"];
    if (fontFile != nil) {
        ref = (GRefObject*)fontFile;
    } else if (fontFile2 != nil) {
        ref = (GRefObject*)fontFile2;
    } else if (fontFile3 != nil) {
        ref = (GRefObject*)fontFile3;
    }
    
    GStreamObject *fontProgram = [parser getObjectByRef:[ref getRefString]];
    fontData = [fontProgram getDecodedStreamContent];
}

- (NSFont*)getNSFontBySize:(CGFloat)fontSize {
    if (!embededFont) {
        NSFont *f = [NSFont fontWithName:noneEmbeddedFontName size:fontSize];
        return f;
    }
    CGDataProviderRef cgData = CGDataProviderCreateWithCFData((CFDataRef)fontData);
    CGFontRef font = CGFontCreateWithDataProvider(cgData);
    NSFont *f = (NSFont*)CFBridgingRelease(CTFontCreateWithGraphicsFont(font, fontSize, nil, nil));
    CFRelease(cgData);
    CFRelease(font);
    return f;
}

- (BOOL)embeddedFont {
    return embededFont;
}
@end
