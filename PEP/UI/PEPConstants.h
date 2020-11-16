//
//  PEPConstants.h
//  PEP
//
//  Created by Aaron Elkins on 11/15/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#ifndef PEPConstants_h
#define PEPConstants_h

#define kAnnotateTabTitle @"Annotate"
#define kEditPDFTabTitle @"Edit PDF"
#define kDrawTabTitle @"Draw"
#define kRecentTabTitle @"Recent"

#define kDarkColor [NSColor colorWithRed:0.26 green:0.28 blue:0.31 alpha:1.0]

#define kTextEditToolText @"Text"
#define kImageToolText @"Image"

// Modes for GDocument
typedef enum {
    kNoneMode,
    kTextEditMode,
    kImageMode
} GDocumentMode;
#endif /* PEPConstants_h */
