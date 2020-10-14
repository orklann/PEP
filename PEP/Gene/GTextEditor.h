//
//  GTextEditor.h
//  PEP
//
//  Created by Aaron Elkins on 10/14/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GTextBlock;
@class GPage;
NS_ASSUME_NONNULL_BEGIN

@interface GTextEditor : NSObject {
    int insertionPointIndex;
    GPage *page;
    GTextBlock *textBlock;
}

+ (id)textEditorWithPage:(GPage *)p textBlock:(GTextBlock *)tb;
- (GTextEditor*)initWithPage:(GPage *)p textBlock:(GTextBlock*)tb;
- (void)draw:(CGContextRef)context;
@end

NS_ASSUME_NONNULL_END
