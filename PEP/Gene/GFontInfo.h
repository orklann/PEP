//
//  GFontInfo.h
//  PEP
//
//  Created by Aaron Elkins on 2/16/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GFontInfo : NSObject {
    
}

@property (readwrite) NSString* fontTag;
@property (readwrite) unichar firstChar;
@property (readwrite) CGFloat missingWidth;
@property (readwrite) NSMutableArray *widths;
@property (readwrite) NSString *subType;

+ (id)create;
- (CGFloat)getCharWidth:(unichar)charCode;
@end

NS_ASSUME_NONNULL_END
