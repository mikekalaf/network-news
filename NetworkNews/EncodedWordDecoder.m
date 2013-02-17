//
//  EncodedWordDecoder.m
//  Network News
//
//  Created by David Schweinsberg on 2/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "EncodedWordDecoder.h"
#import "NNBase64Decoder.h"

static int hexvalue(char c)
{
    if (0x30 <= c && c < 0x3a)
        return c - 0x30;
    else if (0x41 <= c && c < 0x47)
        return c - 0x37;
    else if (0x61 <= c && c < 0x67)
        return c - 0x57;
    
    return 0;
}

@implementation EncodedWordDecoder

+ (CFStringEncoding)charsetEncodingFromName:(NSString *)encodingName
{
    if ([encodingName caseInsensitiveCompare:@"UTF-8"] == NSOrderedSame)
        return kCFStringEncodingUTF8;
    else if ([encodingName caseInsensitiveCompare:@"ISO-8859-1"] == NSOrderedSame)
        return kCFStringEncodingISOLatin1;
    else if ([encodingName caseInsensitiveCompare:@"ISO-8859-2"] == NSOrderedSame)
        return kCFStringEncodingISOLatin2;
    else if ([encodingName caseInsensitiveCompare:@"ISO-8859-15"] == NSOrderedSame)
        return kCFStringEncodingISOLatin9;
    else if ([encodingName caseInsensitiveCompare:@"windows-1252"] == NSOrderedSame)
        return kCFStringEncodingWindowsLatin1;
    else if ([encodingName caseInsensitiveCompare:@"windows-1256"] == NSOrderedSame)
        return kCFStringEncodingWindowsArabic;
    else if ([encodingName caseInsensitiveCompare:@"ISO-2022-JP"] == NSOrderedSame)
        return kCFStringEncodingISO_2022_JP;
    else if ([encodingName caseInsensitiveCompare:@"Big5"] == NSOrderedSame)
        return kCFStringEncodingBig5;
    else if ([encodingName caseInsensitiveCompare:@"KOI8-R"] == NSOrderedSame)
        return kCFStringEncodingKOI8_R;
    else
        return kCFStringEncodingInvalidId;
}

//- (NSString *)decodeData:(NSData *)data
//{
//}

- (NSString *)decodeQString:(NSString *)string
                   encoding:(CFStringEncoding)encoding
{
    NSMutableString *decodedString = [NSMutableString stringWithCapacity:string.length];
    NSMutableData *dataToDecode = nil;
    for (NSUInteger i = 0; i < string.length; ++i)
    {
        unichar c = [string characterAtIndex:i];
        if (c == '=')
        {
            unichar high_c = [string characterAtIndex:i + 1];
            unichar low_c = [string characterAtIndex:i + 2];
            if (ishexnumber(high_c) && ishexnumber(low_c))
            {
                int high = hexvalue(high_c);
                int low = hexvalue(low_c);
                unsigned char value = 16 * high + low;
                
                if (dataToDecode == nil)
                    dataToDecode = [[NSMutableData alloc] initWithCapacity:1];
                
                [dataToDecode appendBytes:&value length:1];
                
                // Is there another value directly following in this sequence?
                // If so, defer the decoding until we have that value also.
                // This is because of multi-byte character encodings.
                if (i + 3 >= string.length
                    || [string characterAtIndex:i + 3] != '=')
                {
                    CFStringRef strRef = CFStringCreateWithBytes(kCFAllocatorDefault,
                                                                 dataToDecode.bytes,
                                                                 dataToDecode.length,
                                                                 encoding,
                                                                 false);
                    [decodedString appendString:(__bridge NSString *)strRef];
                    CFRelease(strRef);
                    dataToDecode = nil;
                }
                i += 2;
                continue;
            }
        }
        else if (c == '_')
        {
            [decodedString appendString:@" "];
            continue;
        }

        [decodedString appendFormat:@"%lc", c];
    }
    
    return decodedString;
}

- (NSString *)decodeBString:(NSString *)string
                   encoding:(CFStringEncoding)encoding
{
    NNBase64Decoder *base64Decoder = [[NNBase64Decoder alloc] init];
    NSString *decodedString = [base64Decoder decodeString:string
                                         toStringEncoding:encoding];
    return decodedString;
}

- (NSString *)decodeEncodedWordString:(NSString *)string
{
    // The encoded-word can be broken into five components
    // (delimited by '?'s):
    // "=", <charset>, <encoding>, <encoded text>, "="
    NSArray *components = [string componentsSeparatedByString:@"?"];
    if (components.count == 5)
    {
        NSString *encodingName = [components objectAtIndex:1];
        CFStringEncoding targetEncoding = [EncodedWordDecoder charsetEncodingFromName:encodingName];
        if (targetEncoding != kCFStringEncodingInvalidId)
        {
            NSString *encoding = [components objectAtIndex:2];
            if ([encoding caseInsensitiveCompare:@"Q"] == NSOrderedSame)
            {
                return [self decodeQString:[components objectAtIndex:3]
                                  encoding:targetEncoding];
            }
            else if ([encoding caseInsensitiveCompare:@"B"] == NSOrderedSame)
            {
                return [self decodeBString:[components objectAtIndex:3]
                                  encoding:targetEncoding];
            }
        }
    }
    
    NSLog(@"Unrecognised encoded-word: %@", components);
    
    return string;
}

- (NSString *)decodeString:(NSString *)string
{
    // Iterate through any "=?"..."?=" pairs in the string
    NSRange searchRange = NSMakeRange(0, string.length);
    
    while (searchRange.length > 6)
    {
        NSRange range1 = [string rangeOfString:@"=?" options:0 range:searchRange];
        if (range1.location == NSNotFound)
            break;
        
        // Scan for three more '?'s, followed by a '='
        NSUInteger delimiterCount = 0;
        NSRange range2 = NSMakeRange(NSNotFound, 0);
//        NSUInteger scanEnd = range1.location + searchRange.length - 1;
        for (NSUInteger i = range1.location + 2; i < string.length - 1; ++i)
        {
            if ([string characterAtIndex:i] == '?')
                ++delimiterCount;
            
            if (delimiterCount == 3 && [string characterAtIndex:i + 1] == '=')
                range2 = NSMakeRange(i, 2);

            if (delimiterCount == 3)
                break;
        }

//        NSRange searchSubrange = NSMakeRange(range1.location + 2,
//                                             string.length - range1.location - 2);
//        NSRange range2 = [string rangeOfString:@"?=" options:0 range:searchSubrange];
        if (range2.location == NSNotFound)
            break;

        NSRange range = NSUnionRange(range1, range2);
        NSString *encodedString = [string substringWithRange:range];
        NSString *decodedString = [self decodeEncodedWordString:encodedString];

        // Recompose the string, substituting the encoded range with
        // the decoded string
        string = [string stringByReplacingCharactersInRange:range
                                                 withString:decodedString];

        // Move on to the next part of this recomposed string
        searchRange = NSMakeRange(range.location + decodedString.length,
                                  string.length - (range.location + decodedString.length));
    }
    return string;
}

@end
