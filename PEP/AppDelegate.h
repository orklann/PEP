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

@property (readwrite) IBOutlet PEPWindow *window;
@property (weak) IBOutlet NSWindow *openPDFWindow;
@property (weak) IBOutlet NSWindow *logPageContentWindow;
@property (weak) IBOutlet NSTextField *pageNumber;

// Bug report, new issue, join discord
- (IBAction)showLogPageWindow:(id)sender;
- (IBAction)logPageContent:(id)sender;
- (IBAction)newIssue:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)joinDiscord:(id)sender;
@end

