//
//  GDocument.h
//  PEP
//
//  Created by Aaron Elkins on 9/9/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GPage.h"
#import "GParser.h"
#import "GConstants.h"
#import "PEPConstants.h"
#import "GTextEditor.h"

NS_ASSUME_NONNULL_BEGIN

@interface GDocument : NSView {
    NSString *file;
    NSMutableArray *pages;
    GParser *parser;
    NSTrackingArea *trackingArea;
    GDocumentMode mode;
    NSMutableArray *visiblePages;
}

@property (readwrite) BOOL forceDrawAllPage;
@property (readwrite) NSMutableArray *addedRefkeys;
@property (readwrite) GTextEditor * _Nullable textEditor;
@property (readwrite) NSMutableArray *dataToUpdate;

- (IBAction)saveDocumentAs:(id)sender;

- (NSMutableArray*)pages;
- (void)saveAs:(NSString*)path;
- (void)parsePages;
- (NSRect)rectFromFlipped:(NSRect)r;
- (void)scrollToTop;
- (void)setMode:(GDocumentMode)m;
- (GDocumentMode)mode;
- (NSString*)generateNewRef;

// Build new xref table and new trailer 
- (NSData*)buildNewXRefTable;
- (NSData*)buildNewTrailer:(GDictionaryObject*)trailerDict
             prevStartXRef:(int)prevStartXRef
              newStartXRef:(int)newStartXRef;
@end

NS_ASSUME_NONNULL_END
