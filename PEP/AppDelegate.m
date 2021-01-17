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
}

- (IBAction)joinDiscord:(id)sender {
#define kDiscordLink @"https://discord.gg/Fvs8xS7As6"
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kDiscordLink]];
}

- (IBAction)openDocument:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setAllowedFileTypes:@[@"pdf"]];
    
    [panel beginWithCompletionHandler:^(NSInteger result){
     if (result == NSFileHandlingPanelOKButton) {
         NSURL *theDoc = [[panel URLs] objectAtIndex:0];
         self.window = [PEPWindow window];
         [self.window initialize];
         [self.window makeKeyAndOrderFront:sender];
         [self.window setDelegate:self];
         
         // Initialize GDocument at last to make sure scrollToTop work correctly
         [self.window.doc setFile:[theDoc path]];
         [self.window.doc awakeFromNib];
     }

    }];
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
