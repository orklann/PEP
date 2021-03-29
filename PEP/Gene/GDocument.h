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
    NSMutableArray *pages;
    GParser *parser;
    NSTrackingArea *trackingArea;
    GDocumentMode mode;
    NSMutableArray *visiblePages;
}

@property (readwrite) NSMutableDictionary *cachedFonts;
@property (readwrite) NSMutableDictionary *fontEncodings;
@property (readwrite) NSMutableDictionary *fontInfos;
@property (readwrite) NSString *file;
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


// Build fonts encoding dictionary
- (void)buildFontEncodings;

// Build fonts infos dictionary
- (void)buildFontInfos;

// Build cached fonts dictionary
- (void)buildCachedFonts;

- (void)resizeToFitAllPages;

// Debug:
- (void)logPageContent:(int)pageNumber;
@end

NS_ASSUME_NONNULL_END
