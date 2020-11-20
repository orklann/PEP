//
//  GTextEditorDelegate.h
//  PEP
//
//  Created by Aaron Elkins on 11/20/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GTextEditor;
NS_ASSUME_NONNULL_BEGIN

@protocol GTextEditorDelegate <NSObject>
@optional
- (void)textStateDidChange:(GTextEditor*)editor;
@end

NS_ASSUME_NONNULL_END
