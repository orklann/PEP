//
//  GCMap.m
//  PEP
//
//  Created by Aaron Elkins on 3/30/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import "GCMap.h"
#import "GObjects.h"

@implementation GCMap
+ (id)create {
    GCMap *cmap = [[GCMap alloc] init];
    return cmap;
}

- (void)eval {
    unicodeMaps = [NSMutableDictionary dictionary];
    // TODO: Do eval
}
@end
