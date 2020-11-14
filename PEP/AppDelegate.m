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
@interface AppDelegate ()

@property (weak) IBOutlet PEPWindow *window;
@end

@implementation AppDelegate

- (IBAction)saveDocumentAs:(id)sender {
    [(GDocument*)self.window.contentView saveDocumentAs:sender];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
