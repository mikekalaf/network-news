//
//  EncodedWordEncoder.m
//  NetworkNews
//
//  Created by David Schweinsberg on 4/9/18.
//  Copyright © 2018 David Schweinsberg. All rights reserved.
//

#import "EncodedWordEncoder.h"

@implementation EncodedWordEncoder

- (nullable NSString *)encodeString:(nonnull NSString *)string
{
    if ([string canBeConvertedToEncoding:NSASCIIStringEncoding])
    {
        // This is just ASCII, so return as is
        return string;
    }
    else if ([string canBeConvertedToEncoding:NSISOLatin1StringEncoding])
    {
        // We'll handle cases where we can use ISO Latin 1
        NSMutableString *encodedStr = [NSMutableString string];
        for (NSUInteger i = 0; i < string.length; ++i)
        {
            unichar c = [string characterAtIndex:i];
            if (c >= 128 || c == '?' || c == '=')
                [encodedStr appendFormat:@"=%02X", c];
            else if (c == ' ')
                [encodedStr appendString:@"_"];
            else
                [encodedStr appendFormat:@"%c", c];
        }
        return [NSString stringWithFormat:@"=?iso-8859-1?Q?%@?=", encodedStr];
    }
    else if ([string canBeConvertedToEncoding:NSUTF8StringEncoding])
    {
        // Otherwise we'll do it as UTF-8
        const char *utf8String = string.UTF8String;
        NSMutableString *encodedStr = [NSMutableString string];
        for (NSUInteger i = 0; utf8String[i] != 0; ++i)
        {
            unsigned char c = utf8String[i];
            if (c >= 128 || c == '?' || c == '=')
                [encodedStr appendFormat:@"=%02X", c];
            else if (c == ' ')
                [encodedStr appendString:@"_"];
            else
                [encodedStr appendFormat:@"%c", c];
        }
        return [NSString stringWithFormat:@"=?utf-8?Q?%@?=", encodedStr];
    }

    return nil;
}

@end
