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
    [f setPage:p];
    [f setFontName:name];
    [f parseFontData];
    return f;
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
    
    // Only get font program for `/FontFile2` for truetype font
    // Other fonts will be in `/FontFile`, `/FontFile3`, we will handle it later
    ref = [[descriptor value] objectForKey:@"FontFile2"];
    GStreamObject *fontProgram = [parser getObjectByRef:[ref getRefString]];
    fontData = [fontProgram getDecodedStreamContent];
    NSLog(@"GFont:fontData with %ld bytes", [fontData length]);
}

- (NSFont*)getNSFontBySize:(CGFloat)fontSize {
    CGDataProviderRef cgData = CGDataProviderCreateWithCFData((CFDataRef)fontData);
    CGFontRef font = CGFontCreateWithDataProvider(cgData);
    NSFont *f = (NSFont*)CFBridgingRelease(CTFontCreateWithGraphicsFont(font, fontSize, nil, nil));
    return f;
}
@end
