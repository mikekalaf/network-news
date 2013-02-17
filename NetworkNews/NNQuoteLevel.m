//
//  NNQuoteLevel.m
//  Network News
//
//  Created by David Schweinsberg on 28/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NNQuoteLevel.h"


@implementation NNQuoteLevel

@synthesize level;
@synthesize range;
@synthesize flowed;
@synthesize signatureDivider;

- (id)initWithLevel:(NSUInteger)aLevel
              range:(NSRange)aRange
             flowed:(BOOL)isFlowed
   signatureDivider:(BOOL)isSignatureDivider
{
    self = [super init];
    if (self)
    {
        level = aLevel;
        range = aRange;
        flowed = isFlowed;
        signatureDivider = isSignatureDivider;
    }
    return self;
}

@end
