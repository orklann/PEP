//
//  GGlyph.h
//  PEP
//
//  Created by Aaron Elkins on 10/5/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GGlyph : NSObject {
    NSRect frame;
    NSString *content;
}
+ (id)create;
- (void)setFrame:(NSRect)f;
- (NSRect)frame;
- (void)setContent:(NSString*)s;
- (NSString*)content;
@end

NS_ASSUME_NONNULL_END
