//
//  PEPToolbarView.h
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PEPTool.h"
NS_ASSUME_NONNULL_BEGIN

#define kToolbarHeight 36

@interface PEPToolbarView : NSView

@property (readwrite) NSMutableArray *tools;
- (void)initToolsForEditPDF;
- (void)removeAllTools;
- (NSRect)getRectForTool:(PEPTool*)tool;
@end

NS_ASSUME_NONNULL_END
