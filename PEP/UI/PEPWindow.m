//
//  PEPWindow.m
//  PEP
//
//  Created by Aaron Elkins on 11/14/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "PEPWindow.h"

@implementation PEPWindow
- (void)awakeFromNib {
    NSLog(@"Debug: PEPWindow awakeFromNib");
    [self setTitle:@""];
    [self setTitlebarAppearsTransparent:YES];
}
@end
