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
    ref = [[font value] objectForKey:@"FontDescriptor"];
    GDictionaryObject *descriptor = [parser getObjectByRef:[ref getRefString]];
    
    // Check if font is embedded font, if not embeded, just return and set embededFont to NO
    if ([[descriptor value] objectForKey:@"FontFile"] == nil &&
        [[descriptor value] objectForKey:@"FontFile2"] == nil &&
        [[descriptor value] objectForKey:@"FontFile3"] == nil) {
        embededFont = NO;
        GLiteralStringsObject *fontFamily = [[descriptor value] objectForKey:@"FontFamily"];
        noneEmbededFontName = [fontFamily value];
        return ;
    }
    
    // Only get font program for `/FontFile2` for truetype font
    // Other fonts will be in `/FontFile`, `/FontFile3`, we will handle it later
    ref = [[descriptor value] objectForKey:@"FontFile2"];
    GStreamObject *fontProgram = [parser getObjectByRef:[ref getRefString]];
    fontData = [fontProgram getDecodedStreamContent];
}

- (NSFont*)getNSFontBySize:(CGFloat)fontSize {
    if (!embededFont) {
        NSFont *f = [NSFont fontWithName:noneEmbededFontName size:fontSize];
        return f;
    }
    CGDataProviderRef cgData = CGDataProviderCreateWithCFData((CFDataRef)fontData);
    CGFontRef font = CGFontCreateWithDataProvider(cgData);
    NSFont *f = (NSFont*)CFBridgingRelease(CTFontCreateWithGraphicsFont(font, fontSize, nil, nil));
    CFRelease(cgData);
    CFRelease(font);
    return f;
}
@end
