//
//  GGlyph.m
//  PEP
//
//  Created by Aaron Elkins on 10/5/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GGlyph.h"

@implementation GGlyph
+ (id)create {
    GGlyph *g = [[GGlyph alloc] init];
    return g;
}

- (void)setFrame:(NSRect)f {
    frame = f;
}

// return frame in GPage coordinate
// In some case, we need view coordinate, just call [GPage rectFromPageToView:]
// to convert to view coordinate
- (NSRect)frame {
    return frame;
}

- (void)setPoint:(NSPoint)p {
    point = p;
}

- (NSPoint)point {
    return point;
}

- (void)setContent:(NSString*)s {
    content = s;
}

- (NSString*)content {
    return content;
}

- (NSString*)literalString {
    NSString *ret;
    if ([content isEqualToString: @"("]) {
        ret = @"\\(";
    } else if ([content isEqualToString:@")"]) {
        ret = @"\\)";
    } else {
        ret = content;
    }
    return ret;
}

- (NSString*)complieToOperators {
    NSMutableString *ret = [NSMutableString string];
    [ret appendString:@"\nQ q "];
    
    // Current context matrix (operator: cm)
    CGAffineTransform ctm = [self ctm];
    NSString *cm = [NSString stringWithFormat:@"%f %f %f %f %f %f cm ",
                    ctm.a, ctm.b, ctm.c, ctm.d, ctm.tx, ctm.ty];
    [ret appendString:cm];
    
    // Text Object
    [ret appendString:@"BT "];
    
    // Text matrix
    CGAffineTransform textMatrix = [self textMatrix];
    NSString *tm = [NSString stringWithFormat:@"%f %f %f %f %f %f Tm ",
                    textMatrix.a, textMatrix.b, textMatrix.c, textMatrix.d,
                    textMatrix.tx, textMatrix.ty];
    [ret appendString:tm];
    
    // Font
    [ret appendFormat:@"%@ %f Tf ", [self fontName], [self fontSize]];
    
    // Tj
    [ret appendFormat:@"(%@) Tj ", [self literalString]];
    
    [ret appendString:@"ET \n"];
    
    return ret;
}
@end
