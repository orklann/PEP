//
//  GOperators.h
//  PEP
//
//  Created by Aaron Elkins on 5/6/21.
//  Copyright © 2021 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GPage;
@class GCommandObject;

// gs operator
@interface GgsOperator : NSObject {
    
}

@property (readwrite) NSString *gsName;

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;
@end

// q operator
@interface GqOperator : NSObject

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;

@end

// Q operator
@interface GQOperator : NSObject

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;

@end

// g operator
@interface GgOperator : NSObject {
    
}

@property (readwrite) GCommandObject *cmdObj;

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;
@end

// G operator
@interface GGOperator : NSObject {
    
}

@property (readwrite) GCommandObject *cmdObj;

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;
@end

// re operator
@interface GreOperator : NSObject {
    
}

@property (readwrite) GCommandObject *cmdObj;

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;
@end


// f* operator
@interface GfStarOperator : NSObject {
    
}

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;
@end


// f operator
@interface GfOperator : NSObject {
    
}

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;
@end


// W* operator
@interface GWStarOperator : NSObject {
    
}

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;
@end


// W operator
@interface GWOperator : NSObject {
    
}

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;
@end



// n operator
@interface GnOperator : NSObject {
    
}

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;
@end

// cs operator
@interface GcsOperator : NSObject {
    
}

@property (readwrite) NSString *colorSpaceName;

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;
@end


// scn operator
@interface GscnOperator : NSObject {
    
}

@property (readwrite) GCommandObject *cmdObj;

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;
@end


// m operator
@interface GmOperator : NSObject {
    
}

@property (readwrite) GCommandObject *cmdObj;

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;
@end


// S operator
@interface GSOperator : NSObject {
    
}

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;
@end


// h operator
@interface GhOperator : NSObject {
    
}

+ (id)create;
- (void)eval:(CGContextRef)context page:(GPage*)page;
@end

NS_ASSUME_NONNULL_END