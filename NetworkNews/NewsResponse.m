//
//  NewsResponse.m
//  NetworkNews
//
//  Created by David Schweinsberg on 8/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "NewsResponse.h"

@implementation NewsResponse

- (instancetype)initWithData:(NSData *)data statusCode:(NSInteger)statusCode {
  self = [super init];
  if (self) {
    _data = data;
    _statusCode = statusCode;
  }
  return self;
}

- (NSString *)string {
  return [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
}

@end
