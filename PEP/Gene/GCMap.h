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
    
}

@property (readwrite) GStreamObject *stream;
@property (readwrite) NSMutableDictionary *unicodeMaps;

+ (id)create;
- (void)eval;
- (void)eval:(NSData*)data;
- (void)setUnicodeMap:(int)i value:(NSString*)s;
@end

NS_ASSUME_NONNULL_END
