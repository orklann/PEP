//
//  GFontEncoding.h
//  PEP
//
//  Created by Aaron Elkins on 2/25/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GObjects.h"

NS_ASSUME_NONNULL_BEGIN

@interface GFontEncoding : NSObject {
    
}

@property (readwrite) NSString *encoding;
@property (readwrite) NSMutableDictionary *differences;

+ (id)create;
- (void)parseDifference:(GArrayObject*)differenceArray;
- (NSString*)getGlyphNameInDifferences:(int)codeIndex;
@end

NS_ASSUME_NONNULL_END
