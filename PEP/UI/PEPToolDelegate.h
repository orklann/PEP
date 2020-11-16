//
//  PEPToolDelegate.h
//  PEP
//
//  Created by Aaron Elkins on 11/16/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#ifndef PEPToolDelegate_h
#define PEPToolDelegate_h

#import <Foundation/Foundation.h>

@class PEPTool;

@protocol PEPToolDelegate <NSObject>
@optional
- (void)toolDidActive:(PEPTool*)tool;
@end

#endif /* PEPToolDelegate_h */
