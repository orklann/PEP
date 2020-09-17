//
//  GPage.h
//  PEP
//
//  Created by Aaron Elkins on 9/17/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GObjects.h"

NS_ASSUME_NONNULL_BEGIN

@interface GPage : NSObject {
    GDictionaryObject *pageDictionary;
}

+ (id)create;
- (void)setPageDictionary:(GDictionaryObject*)d;
- (GDictionaryObject*)pageDictionary;
@end

NS_ASSUME_NONNULL_END
