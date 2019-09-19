//
//  LineIterator.m
//  Network News
//
//  Created by David Schweinsberg on 15/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "LineIterator.h"

@implementation LineIterator

@synthesize partial;
@synthesize lineNumber;

- (instancetype)initWithData:(NSData *)aData {
  self = [super init];
  if (self) {
    data = aData;
    position = 0;
    partial = YES;
    lineNumber = 0;
  }
  return self;
}

- (BOOL)isAtEnd {
  return position >= data.length;
}

- (NSString *)nextLine {
  NSUInteger start = position;
  const char *bytes = data.bytes;
  NSUInteger length = data.length;

  partial = YES;
  ++lineNumber;

  while (position < length) {
    if (bytes[position] == 13 && bytes[position + 1] == 10) {
      // End-of-line
      partial = NO;
      position += 2; // include the CRLF
      break;
    } else if (bytes[position] == 10) {
      // Missing CR -- possibly from split line
      partial = NO;
      ++position; // include the LF
      break;
    } else
      ++position;
  }

  NSString *line = [[NSString alloc] initWithBytes:bytes + start
                                            length:position - start
                                          encoding:NSUTF8StringEncoding];
  if (!line) {
    line = [[NSString alloc] initWithBytes:bytes + start
                                    length:position - start
                                  encoding:NSISOLatin1StringEncoding];
  }

  return line;
}

@end
