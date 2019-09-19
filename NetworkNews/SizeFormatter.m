//
//  SizeFormatter.m
//  Network News
//
//  Created by David Schweinsberg on 21/12/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import "SizeFormatter.h"

#define ONE_KB 1024
#define ONE_MB 1048576

@implementation SizeFormatter

- (NSString *)stringForObjectValue:(id)obj {
  if ([obj isKindOfClass:[NSNumber class]]) {
    NSNumber *number = obj;
    NSUInteger value = number.integerValue;
    if (value < ONE_KB)
      return [NSString stringWithFormat:@"%lu B", (unsigned long)value];
    else if (value < ONE_MB)
      return
          [NSString stringWithFormat:@"%lu KB", (unsigned long)value / ONE_KB];
    else
      return
          [NSString stringWithFormat:@"%lu MB", (unsigned long)value / ONE_MB];
  }
  return nil;
}

- (BOOL)getObjectValue:(id *)obj
             forString:(NSString *)string
      errorDescription:(NSString **)errorString {
  *obj = nil;
  return YES;
}

@end
