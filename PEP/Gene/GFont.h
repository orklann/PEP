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
}
+ (id)fontWithName:(NSString*)name page:(GPage*)p;
- (void)setFontName:(NSString*)name;
- (void)setPage:(GPage*)p;
@end

NS_ASSUME_NONNULL_END
