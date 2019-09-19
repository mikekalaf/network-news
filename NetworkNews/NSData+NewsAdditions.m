//
//  NSData+NewsAdditions.m
//  Network News
//
//  Created by David Schweinsberg on 4/03/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NSData+NewsAdditions.h"
#import <zlib.h>

@implementation NSData (NewsAdditions)

- (NSUInteger)CRC32 {
  return crc32(0, self.bytes, (unsigned int)self.length);
}

- (NSData *)dataWithCRLFs {
  NSMutableData *data = [NSMutableData data];
  const char *bytes = self.bytes;
  NSUInteger len = self.length;
  NSUInteger start = 0;
  NSUInteger i;
  for (i = 0; i < len; ++i) {
    if (i > 0 && bytes[i - 1] != 13 && bytes[i] == 10) {
      [data appendBytes:bytes + start length:i - start];
      [data appendBytes:"\r\n" length:2];
      start = i + 1;
    } else if (bytes[i] == 13 && bytes[i + 1] != 10) {
      [data appendBytes:bytes + start length:i - start];
      [data appendBytes:"\r\n" length:2];
      start = i + 1;
    }
  }
  if (i - start > 0) {
    [data appendBytes:bytes + start length:i - start];
    //        [data appendBytes:"\r\n" length:2];
  }
  return data;
}

@end
