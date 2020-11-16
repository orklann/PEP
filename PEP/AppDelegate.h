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

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate,
                                    PEPTabDelegate, PEPToolDelegate>

@end

