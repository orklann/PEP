//
//  AppDelegate.h
//  PEP
//
//  Created by Aaron Elkins on 8/21/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PEPTabDelegate.h"
#import "PEPToolDelegate.h"
#import "PEPWindow.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate,
                                    PEPTabDelegate, PEPToolDelegate>

@property (weak) IBOutlet PEPWindow *window;
@property (weak) IBOutlet NSWindow *openPDFWindow;

// Bug report, new issue
- (IBAction)newIssue:(id)sender;
@end

