//
//  NSString+NewsAdditions.m
//  Network News
//
//  Created by David Schweinsberg on 27/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NSString+NewsAdditions.h"

@implementation NSString (NewsAdditions)

- (NSString *)shortGroupName
{
    // Represents all hierarchy levels, except the last, just by its initial
    NSArray *components = [self componentsSeparatedByString:@"."];
    NSMutableString *shortName = [NSMutableString string];
    NSUInteger index = 0;
    for (NSString *str in components)
    {
        if (index == components.count - 1)
            [shortName appendString:str];
        else
            [shortName appendFormat:@"%c.", [str characterAtIndex:0]];
        ++index;
    }
    return shortName;
}

- (NSArray *)rangesWrappingWordsAtColumn:(NSUInteger)location
{
    NSMutableArray *ranges = [NSMutableArray array];
    NSRange range = NSMakeRange(0, location);
    BOOL softLineBreak = NO;
    while (range.location < self.length)
    {
        // If this line starts with a quote marker, include the line without any
        // additional line wrapping
        if ([self characterAtIndex:range.location] == '>')
        {
            NSRange rangeUntilEnd = NSMakeRange(range.location, self.length - range.location);
            NSRange lfRange = [self rangeOfString:@"\n"
                                          options:0
                                            range:rangeUntilEnd];
            if (lfRange.location != NSNotFound)
            {
                NSRange lineRange = NSMakeRange(range.location,
                                                lfRange.location - range.location);
                [ranges addObject:[NSValue valueWithRange:lineRange]];
                range.location += lineRange.length + 1;
                continue;
            }
            else
            {
                [ranges addObject:[NSValue valueWithRange:rangeUntilEnd]];
                break;
            }
        }

        if (softLineBreak)
        {
            // Since we've just had a soft line break, we'll skip any spaces
            // that preceed the text on this next line
            if ([self characterAtIndex:range.location] == ' ')
            {
                ++range.location;
                continue;
            }
            softLineBreak = NO;
        }

        range.length = MIN(location, self.length - range.location);
        
        // Is there a hard line break within the range?
        NSRange lfRange = [self rangeOfString:@"\n"
                                      options:0
                                        range:range];
        if (lfRange.location != NSNotFound)
        {
            NSRange lineRange = NSMakeRange(range.location,
                                            lfRange.location - range.location);
            [ranges addObject:[NSValue valueWithRange:lineRange]];
            range.location = lfRange.location + 1;
            
//            NSLog(@"hard line: '%@'", [self substringWithRange:lineRange]);
            continue;
        }
        
        // Only search for a breaking space if there is more than a line's worth
        // of text remaining
        if (self.length - range.location > location)
        {
            NSRange spaceRange = [self rangeOfString:@" "
                                             options:NSBackwardsSearch
                                               range:range];
            if (spaceRange.location != NSNotFound)
            {
                NSRange lineRange = NSMakeRange(range.location,
                                                spaceRange.location - range.location + 1);
                [ranges addObject:[NSValue valueWithRange:lineRange]];
                range.location = spaceRange.location + 1;
                softLineBreak = YES;
                
//                NSLog(@"soft line: '%@'", [self substringWithRange:lineRange]);
                continue;
            }
        }
        
        if (range.location + range.length < self.length)
        {
            // This is a line that exceeds the column limit.  Find the first
            // point we can break
            NSRange extendedRange = NSMakeRange(range.location,
                                                self.length - range.location);
            NSRange overRange = [self rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
                                                      options:0
                                                        range:extendedRange];
            if (overRange.location != NSNotFound)
            {
                // Is this a hard line or soft line break?
                NSUInteger adjust = 0;
                if ([self characterAtIndex:overRange.location] == ' ')
                {
                    adjust = 1;
                    softLineBreak = YES;
                }

                NSRange lineRange = NSMakeRange(range.location,
                                                overRange.location - range.location + adjust);
                [ranges addObject:[NSValue valueWithRange:lineRange]];
                range.location = overRange.location + 1;
                
//                NSLog(@"ext line: '%@'", [self substringWithRange:lineRange]);
                continue;
            }
        }

        // This is the last line
        [ranges addObject:[NSValue valueWithRange:range]];
        
//        NSLog(@"last line: '%@'", [self substringWithRange:range]);
        
        range.location += range.length;
    }
    return ranges;
}

- (NSString *)stringByWrappingUnquotedWordsAtColumn:(NSUInteger)location
{
    NSArray *ranges = [self rangesWrappingWordsAtColumn:location];
    NSMutableString *wrappedString = [NSMutableString stringWithCapacity:self.length];
    for (NSValue *rangeValue in ranges)
    {
        NSRange range = rangeValue.rangeValue;
        if (wrappedString.length > 0)
            [wrappedString appendString:@"\n"];
        [wrappedString appendString:[self substringWithRange:range]];
    }
    return wrappedString;
}

- (NSString *)messageIDFileName
{
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"<>"];
    NSString *str = [self stringByTrimmingCharactersInSet:charSet];
    NSMutableCharacterSet *pathCharSet = [NSCharacterSet.URLPathAllowedCharacterSet mutableCopy];
    [pathCharSet removeCharactersInString:@"/"];
    str = [str stringByAddingPercentEncodingWithAllowedCharacters:pathCharSet];
    return str;
}

- (NSString *)stringByReplacingOccurrencesOfNumbersWithString:(NSString *)replacement
{
    NSMutableString *newString = [self mutableCopy];
    NSRange searchRange = NSMakeRange(0, self.length);
    while (searchRange.length)
    {
        NSRange range = [self rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]
                                              options:0
                                                range:searchRange];
        if (range.location == NSNotFound)
            break;

        [newString replaceCharactersInRange:range withString:replacement];
        searchRange.location = NSMaxRange(range);
        searchRange.length = self.length - searchRange.location;
    }
    return newString;
}

@end
