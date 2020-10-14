//
//  GTextEditor.m
//  PEP
//
//  Created by Aaron Elkins on 10/14/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GTextEditor.h"
#import "GPage.h"
#import "GTextBlock.h"

@implementation GTextEditor
+ (id)textEditorWithPage:(GPage *)p textBlock:(GTextBlock *)tb {
    GTextEditor *editor = [[GTextEditor alloc] initWithPage:p textBlock:tb];
    return editor;
}

- (GTextEditor*)initWithPage:(GPage *)p textBlock:(GTextBlock*)tb {
    self = [super init];
    page = p;
    textBlock = tb;
    insertionPointIndex = 0;
    return self;
}

- (void)draw:(CGContextRef)context {
    NSLog(@"GTextEditor draw()");
    NSLog(@"GTextEditor insertion point index: %d", insertionPointIndex);
}
@end
