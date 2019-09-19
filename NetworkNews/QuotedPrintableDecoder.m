//
//  QuotedPrintableDecoder.m
//  Network News
//
//  Created by David Schweinsberg on 1/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "QuotedPrintableDecoder.h"
#import "NNHeaderEntry.h"

static int hexvalue(char c) {
  if (0x30 <= c && c < 0x3a)
    return c - 0x30;
  else if (0x41 <= c && c < 0x47)
    return c - 0x37;
  else if (0x61 <= c && c < 0x67)
    return c - 0x57;

  return 0;
}

@implementation QuotedPrintableDecoder

+ (BOOL)isQuotedPrintable:(NSArray *)headers {
  for (NNHeaderEntry *entry in headers) {
    if ([entry.name caseInsensitiveCompare:@"Content-Transfer-Encoding"] ==
        NSOrderedSame) {
      // TODO: A more robust parsing is required due to the possible
      // insertion of comments
      if ([entry.value caseInsensitiveCompare:@"quoted-printable"] ==
          NSOrderedSame)
        return YES;
      else
        return NO;
    }
  }
  return NO;
}

- (NSData *)decodeData:(NSData *)data {
  const char *bytes = data.bytes;
  NSUInteger length = data.length;
  NSMutableData *decodedData = [NSMutableData dataWithCapacity:length];

  for (NSUInteger i = 0; i < length; ++i) {
    if (bytes[i] == '=') {
      if (ishexnumber(bytes[i + 1]) && ishexnumber(bytes[i + 2])) {
        int high = hexvalue(bytes[i + 1]);
        int low = hexvalue(bytes[i + 2]);
        char value = 16 * high + low;
        [decodedData appendBytes:&value length:1];
        i += 2;
      } else if (bytes[i + 1] == 13 && bytes[i + 2] == 10) {
        // Skip
        i += 2;
      }
    } else {
      [decodedData appendBytes:bytes + i length:1];
    }
  }
  return decodedData;
}

@end
