//
//  GCMap.h
//  PEP
//
//  Created by Aaron Elkins on 3/30/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class GStreamObject;
@interface GCMap : NSObject {
    NSMutableDictionary *unicodeMaps;
}

@property (readwrite) GStreamObject *stream;

+ (id)create;
- (void)initThings;
- (void)eval;
@end

NS_ASSUME_NONNULL_END
