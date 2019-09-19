//
//  NSArray+NewsAdditions.m
//  Network News
//
//  Created by David Schweinsberg on 30/11/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import "NSArray+NewsAdditions.h"

@implementation NSArray (NewsAdditions)

- (NSObject *)head {
  if (self.count > 0)
    return self[0];
  else
    return nil;
}

- (NSArray *)tail {
  if (self.count > 1) {
    NSRange range = NSMakeRange(1, self.count - 1);
    return [self subarrayWithRange:range];
  } else
    return nil;
}

- (id)objectWithName:(NSString *)name {
  for (id obj in self)
    if ([[obj name] isEqualToString:name])
      return obj;
  return nil;
}

@end
