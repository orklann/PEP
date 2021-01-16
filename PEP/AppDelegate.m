//
//  AppDelegate.m
//  PEP
//
//  Created by Aaron Elkins on 8/21/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "AppDelegate.h"
#import "GDocument.h"
#import "PEPWindow.h"
#import "PEPConstants.h"


@implementation AppDelegate

- (IBAction)newIssue:(id)sender {
#define kNewIssueLink @"https://github.com/orklann/PEP/issues/new"
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kNewIssueLink]];
    NSLog(@"newIssue");
}

- (IBAction)openDocument:(id)sender {
    self.window = [PEPWindow window];
    [self.window makeKeyAndOrderFront:sender];
    [self.window setDelegate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)windowWillExitFullScreen:(NSNotification *)notification {
    [self.window needToMoveButtons];
}

- (void)windowDidResize:(NSNotification *)notification {
    [self.window needToMoveButtons];
}

- (void)tabDidActive:(PEPTab *)tab {
    NSLog(@"Tab actived: %@", [tab title]);
    if ([[tab title] isEqualToString:kEditPDFTabTitle]) {
        [[(PEPWindow*)self.window toolbarView] removeAllTools];
        [[(PEPWindow*)self.window toolbarView] initToolsForEditPDF];
    } else {
        [[(PEPWindow*)self.window toolbarView] removeAllTools];
        PEPWindow* window = (PEPWindow*)self.window;
        GDocument *doc = (GDocument*)[window doc];
        [doc setMode:kNoneMode];
    }
}

- (void)toolDidActive:(PEPTool *)tool {
    NSLog(@"Tool selected: %@", [tool text]);
    if ([[tool text] isEqualToString:kTextEditToolText]) {
        PEPWindow* window = (PEPWindow*)self.window;
        GDocument *doc = (GDocument*)[window doc];
        [doc setMode:kTextEditMode];
    } else if ([[tool text] isEqualToString:kImageToolText]) {
        PEPWindow* window = (PEPWindow*)self.window;
        GDocument *doc = (GDocument*)[window doc];
        [doc setMode:kImageMode];
    }
}
@end
