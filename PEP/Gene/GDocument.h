//
//  GDocument.h
//  PEP
//
//  Created by Aaron Elkins on 9/9/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GPage.h"
#import "GParser.h"

NS_ASSUME_NONNULL_BEGIN

// Unit in user space is 1/72 inch, and we assume device spaces PPI is
// 96 (96 pixels per inch), so we get the scale factor is 1/72*96
#define kScaleFactor 96.0/72.0

@interface GDocument : NSView {
    NSMutableAttributedString *s;
    NSString *file;
    NSMutableArray *pages;
    GParser *parser;
}

- (void)parsePages;
- (NSRect)rectFromFlipped:(NSRect)r;
- (void)scrollToTop;
@end

NS_ASSUME_NONNULL_END
