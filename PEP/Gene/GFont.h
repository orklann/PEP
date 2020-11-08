//
//  GFont.h
//  PEP
//
//  Created by Aaron Elkins on 9/24/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GPage;
NS_ASSUME_NONNULL_BEGIN

@interface GFont : NSObject {
    GPage *page;
    NSData *fontData;
    NSString *fontName;
    BOOL embededFont;
    NSString *noneEmbeddedFontName;
}
+ (id)fontWithName:(NSString*)name page:(GPage*)p;
- (void)setEmbededFont:(BOOL)v;
- (void)setFontName:(NSString*)name;
- (void)setPage:(GPage*)p;
- (NSFont*)getNSFontBySize:(CGFloat)fontSize;
@end

NS_ASSUME_NONNULL_END
