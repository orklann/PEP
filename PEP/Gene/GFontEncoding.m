//
//  GFontEncoding.m
//  PEP
//
//  Created by Aaron Elkins on 2/25/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GFontEncoding.h"

@implementation GFontEncoding

+ (id)create {
    GFontEncoding *o = [[GFontEncoding alloc] init];
    return o;
}

- (void)parseDifference:(GArrayObject*)differenceArray {
    _differences = [NSMutableDictionary dictionary];
    NSInteger startIndex = 0;
    for (GObject *ele in [differenceArray value]) {
        if ([ele type] == kNumberObject) {
            startIndex = (int)[(GNumberObject*)ele getRealValue];
        } else {
            NSNumber *index = [NSNumber numberWithInteger:startIndex];
            NSString *glyphName = [(GNameObject*)ele value];
            [_differences setObject:glyphName forKey:index];
            startIndex++;
        }
    }
}

- (NSString*)getGlyphNameInDifferences:(int)codeIndex {
    NSNumber *index = [NSNumber numberWithInt:codeIndex];
    NSString *glyphName = [_differences objectForKey:index];
    return glyphName;
}
@end
