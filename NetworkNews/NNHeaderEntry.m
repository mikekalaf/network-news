//
//  NNHeaderEntry.m
//  Network News
//
//  Created by David Schweinsberg on 8/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NNHeaderEntry.h"


@implementation NNHeaderEntry

@synthesize name;
@synthesize value;

- (instancetype)initWithName:(NSString *)aName value:(NSString *)aValue
{
    self = [super init];
    if (self)
    {
        name = [aName copy];
        value = [aValue copy];
    }
    return self;
}

@end
