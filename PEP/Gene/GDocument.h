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
#import "GConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface GDocument : NSView {
    NSMutableAttributedString *s;
    NSString *file;
    NSMutableArray *pages;
    GParser *parser;
    NSTrackingArea *trackingArea;
}

- (IBAction)saveDocumentAs:(id)sender;
- (void)parsePages;
- (NSRect)rectFromFlipped:(NSRect)r;
- (void)scrollToTop;
@end

NS_ASSUME_NONNULL_END
