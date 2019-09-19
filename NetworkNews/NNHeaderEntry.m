//
//  NNHeaderEntry.m
//  Network News
//
//  Created by David Schweinsberg on 8/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NNHeaderEntry.h"

@implementation NNHeaderEntry

- (instancetype)initWithName:(NSString *)aName value:(NSString *)aValue {
  self = [super init];
  if (self) {
    _name = [aName copy];
    _value = [aValue copy];
  }
  return self;
}

@end
