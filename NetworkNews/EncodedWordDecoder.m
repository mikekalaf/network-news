//
//  EncodedWordDecoder.m
//  Network News
//
//  Created by David Schweinsberg on 2/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "EncodedWordDecoder.h"
#import "NNBase64Decoder.h"

static int hexvalue(char c) {
  if (0x30 <= c && c < 0x3a)
    return c - 0x30;
  else if (0x41 <= c && c < 0x47)
    return c - 0x37;
  else if (0x61 <= c && c < 0x67)
    return c - 0x57;

  return 0;
}

@implementation EncodedWordDecoder

//- (NSString *)decodeData:(NSData *)data
//{
//}

- (NSString *)decodeQString:(NSString *)string
                   encoding:(NSStringEncoding)encoding {
  NSMutableString *decodedString =
      [NSMutableString stringWithCapacity:string.length];
  NSMutableData *dataToDecode = nil;
  for (NSUInteger i = 0; i < string.length; ++i) {
    unichar c = [string characterAtIndex:i];
    if (c == '=') {
      unichar high_c = [string characterAtIndex:i + 1];
      unichar low_c = [string characterAtIndex:i + 2];
      if (ishexnumber(high_c) && ishexnumber(low_c)) {
        int high = hexvalue(high_c);
        int low = hexvalue(low_c);
        unsigned char value = 16 * high + low;

        if (dataToDecode == nil)
          dataToDecode = [[NSMutableData alloc] initWithCapacity:1];

        [dataToDecode appendBytes:&value length:1];

        // Is there another value directly following in this sequence?
        // If so, defer the decoding until we have that value also.
        // This is because of multi-byte character encodings.
        if (i + 3 >= string.length || [string characterAtIndex:i + 3] != '=') {
          @try {
            NSString *str = [[NSString alloc] initWithData:dataToDecode
                                                  encoding:encoding];
            [decodedString appendString:str];
          } @catch (NSException *exception) {
            NSString *str =
                [[NSString alloc] initWithData:dataToDecode
                                      encoding:NSISOLatin1StringEncoding];
            [decodedString appendString:str];
          }
          dataToDecode = nil;
        }
        i += 2;
        continue;
      }
    } else if (c == '_') {
      [decodedString appendString:@" "];
      continue;
    }

    [decodedString appendFormat:@"%lc", c];
  }

  return decodedString;
}

- (NSString *)decodeBString:(NSString *)string
                   encoding:(NSStringEncoding)encoding {
  NSString *decodedString = [NNBase64Decoder decodeString:string
                                         toStringEncoding:encoding];
  return decodedString;
}

- (NSString *)decodeEncodedWordString:(NSString *)string {
  // The encoded-word can be broken into five components
  // (delimited by '?'s):
  // "=", <charset>, <encoding>, <encoded text>, "="
  NSArray *components = [string componentsSeparatedByString:@"?"];
  if (components.count == 5) {
    NSString *encodingName = components[1];

    CFStringEncoding targetCFStringEncoding =
        CFStringConvertIANACharSetNameToEncoding(
            (__bridge CFStringRef)(encodingName));
    NSStringEncoding targetEncoding =
        CFStringConvertEncodingToNSStringEncoding(targetCFStringEncoding);
    NSString *encoding = components[2];
    if ([encoding caseInsensitiveCompare:@"Q"] == NSOrderedSame) {
      return [self decodeQString:components[3] encoding:targetEncoding];
    } else if ([encoding caseInsensitiveCompare:@"B"] == NSOrderedSame) {
      return [self decodeBString:components[3] encoding:targetEncoding];
    }
  }

  NSLog(@"Unrecognised encoded-word: %@", components);

  return string;
}

- (NSString *)decodeString:(NSString *)string {
  // Iterate through any "=?"..."?=" pairs in the string
  NSRange searchRange = NSMakeRange(0, string.length);

  while (searchRange.length > 6) {
    NSRange range1 = [string rangeOfString:@"=?" options:0 range:searchRange];
    if (range1.location == NSNotFound)
      break;

    // Scan for three more '?'s, followed by a '='
    NSUInteger delimiterCount = 0;
    NSRange range2 = NSMakeRange(NSNotFound, 0);
    //        NSUInteger scanEnd = range1.location + searchRange.length - 1;
    for (NSUInteger i = range1.location + 2; i < string.length - 1; ++i) {
      if ([string characterAtIndex:i] == '?')
        ++delimiterCount;

      if (delimiterCount == 3 && [string characterAtIndex:i + 1] == '=')
        range2 = NSMakeRange(i, 2);

      if (delimiterCount == 3)
        break;
    }

    //        NSRange searchSubrange = NSMakeRange(range1.location + 2,
    //                                             string.length -
    //                                             range1.location - 2);
    //        NSRange range2 = [string rangeOfString:@"?=" options:0
    //        range:searchSubrange];
    if (range2.location == NSNotFound)
      break;

    NSRange range = NSUnionRange(range1, range2);
    NSString *encodedString = [string substringWithRange:range];
    NSString *decodedString = [self decodeEncodedWordString:encodedString];

    if (decodedString == nil)
      break;

    // Recompose the string, substituting the encoded range with
    // the decoded string
    string = [string stringByReplacingCharactersInRange:range
                                             withString:decodedString];

    // Move on to the next part of this recomposed string
    searchRange =
        NSMakeRange(range.location + decodedString.length,
                    string.length - (range.location + decodedString.length));
  }
  return string;
}

@end
