//
//  NNQuoteLevelParser.m
//  Network News
//
//  Created by David Schweinsberg on 28/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NNQuoteLevelParser.h"
#import "NNQuoteLevel.h"

@implementation NNQuoteLevelParser

- (instancetype)initWithData:(NSData *)aData
            flowed:(BOOL)isFlowed
{
    self = [super init];
    if (self)
    {
        data = aData;
        flowed = isFlowed;
    }
    return self;
}

- (NSUInteger)quoteLevelOfRange:(NSRange)range offset:(NSUInteger *)offset
{
    // Count the number of '>' characters preceeding the first
    // non-white-space character
    const char *bytes = data.bytes + range.location;
    NSUInteger level = 0;
    NSUInteger i;
    for (i = 0; i < range.length; ++i)
    {
        if (bytes[i] == '>')
            ++level;
        else if (!isblank(bytes[i]))
            break;
    }
    if (offset)
        *offset = i;
    return level;
}

- (NSArray *)parseLines
{
    // Build an array of quote levels, one for each line of the article body.
    // The range in each quote level is to cover just the actual text, and
    // excludes the preceeding quote markers (">"), but including the CRLFs.
    const char *bytes = data.bytes;
    NSUInteger length = data.length;
    NSUInteger start = 0;
    NSMutableArray *quoteLevels = [NSMutableArray arrayWithCapacity:1];
    NNQuoteLevel *previousSigQL = nil;
    
    for (NSUInteger i = 0; i < length; ++i)
    {
        if (bytes[i] == 13 && bytes[i + 1] == 10)
        {
            // Check if line is flowed under "format=flowed"
            BOOL lineFlowed = NO;
            if (flowed && i > 0 && bytes[i - 1] == 32)
                lineFlowed = YES;

            NSRange range = NSMakeRange(start, i - start);
            NSUInteger offset;
            NSUInteger level = [self quoteLevelOfRange:range offset:&offset];
            range.location += offset;
            range.length -= offset;
            
            // Is this possibly a signature divider?
            BOOL sigDiv = NO;
            if (level == 0 && range.length == 3)
            {
                if (memcmp(bytes + range.location, "-- ", 3) == 0)
                {
                    sigDiv = YES;
                    lineFlowed = NO;
                }
            }
            
            NNQuoteLevel *ql = [[NNQuoteLevel alloc] initWithLevel:level
                                                             range:range
                                                            flowed:lineFlowed
                                                  signatureDivider:sigDiv];
            [quoteLevels addObject:ql];
            start = i + 2; // Skip CRLF
            
            // Do we need to reverse a previous signature divider detection?
            // (Only the last one found should be part of a signature)
            if (sigDiv)
            {
                if (previousSigQL)
                {
                    previousSigQL.signatureDivider = NO;
                    previousSigQL.flowed = YES;
                }
                previousSigQL = ql;
            }
        }
    }
    return quoteLevels;
}

- (NSArray *)quoteLevels
{
    return [self parseLines];
}

@end
