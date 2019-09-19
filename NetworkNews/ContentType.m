//
//  ContentType.m
//  Network News
//
//  Created by David Schweinsberg on 6/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ContentType.h"

@implementation ContentType

- (instancetype)initWithString:(NSString *)string {
  self = [super init];
  if (self) {
    NSArray *components = [string componentsSeparatedByString:@";"];
    self.mediaType = components[0];

    if (components.count > 1) {
      NSCharacterSet *set =
          [NSCharacterSet characterSetWithCharactersInString:@" \""];

      // Parse any parameters
      for (NSUInteger i = 1; i < components.count; ++i) {
        NSArray *paramComponents =
            [components[i] componentsSeparatedByString:@"="];
        if (paramComponents.count == 2) {
          NSString *name =
              [paramComponents[0] stringByTrimmingCharactersInSet:set];
          NSString *value =
              [paramComponents[1] stringByTrimmingCharactersInSet:set];

          if ([name caseInsensitiveCompare:@"charset"] == NSOrderedSame)
            self.charset = value.lowercaseString;
          else if ([name caseInsensitiveCompare:@"format"] == NSOrderedSame)
            self.format = value.lowercaseString;
          else if ([name caseInsensitiveCompare:@"name"] == NSOrderedSame)
            self.name = value;
        }
      }
    }
  }
  return self;
}

- (BOOL)isFormatFlowed {
  return [_format isEqualToString:@"flowed"];
}

@end
