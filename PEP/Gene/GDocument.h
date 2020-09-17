//
//  GDocument.h
//  PEP
//
//  Created by Aaron Elkins on 9/9/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GPage.h"

NS_ASSUME_NONNULL_BEGIN

@interface GDocument : NSView {
    NSMutableAttributedString *s;
    NSString *file;
    NSMutableArray *pages;
}

- (void)parsePages;
@end

NS_ASSUME_NONNULL_END
