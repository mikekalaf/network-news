//
//  YEncDecoder.m
//  Network News
//
//  Created by David Schweinsberg on 26/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "YEncDecoder.h"
#import "NSData+NewsAdditions.h"

// These functions depend on working with data that still retains the message
// headers, and therefore the "=y" will never occur on the first line

static NSUInteger scanForPair(const char *bytes, NSUInteger startOffset, NSUInteger length)
{
    for (NSUInteger i = startOffset; i < length - 4; ++i)
    {
        if (i == startOffset
            && bytes[i] == '='
            && bytes[i + 1] == 'y')
            return i;

        if (bytes[i] == 13
            && bytes[i + 1] == 10
            && bytes[i + 2] == '='
            && bytes[i + 3] == 'y')
            return i + 2;
    }
    return NSUIntegerMax;
}

static NSUInteger scanForNextLine(const char *bytes, NSUInteger startOffset, NSUInteger length)
{
    for (NSUInteger i = startOffset; i < length - 1; ++i)
    {
        if (bytes[i] == 13 && bytes[i + 1] == 10)
            return i + 2;
    }
    return NSUIntegerMax;
}

static void scanForBeginFields(const char *bytes,
                               NSUInteger startOffset,
                               NSUInteger length,
                               NSString **fileName,
                               NSUInteger *part)
{
    NSUInteger fieldNameOffset = startOffset;
    for (NSUInteger i = startOffset; i < length; ++i)
    {
        if (bytes[i] == '=')
        {
            if ((i - fieldNameOffset == 4)
                && bytes[fieldNameOffset] == 'n'
                && bytes[fieldNameOffset + 1] == 'a'
                && bytes[fieldNameOffset + 2] == 'm'
                && bytes[fieldNameOffset + 3] == 'e')
            {
                // This is the filename field up to the end of the line
                *fileName = [[NSString alloc] initWithBytes:bytes + i + 1
                                                     length:length - i - 1
                                                   encoding:NSASCIIStringEncoding];
                return;
            }
            else if ((i - fieldNameOffset == 4)
                     && bytes[fieldNameOffset] == 'p'
                     && bytes[fieldNameOffset + 1] == 'a'
                     && bytes[fieldNameOffset + 2] == 'r'
                     && bytes[fieldNameOffset + 3] == 't')
            {
                *part = strtoll(bytes + i + 1, NULL, 10);
            }
        }
        else if (bytes[i] == ' ')
        {
            fieldNameOffset = i + 1;
        }
    }
}

static void scanForEndFields(const char *bytes,
                             NSUInteger startOffset,
                             NSUInteger length,
                             NSUInteger *size,
                             NSUInteger *crc32)
{
    NSUInteger fieldNameOffset = startOffset;
    for (NSUInteger i = startOffset; i < length; ++i)
    {
        if (bytes[i] == '=')
        {
            if ((i - fieldNameOffset == 4)
                && bytes[fieldNameOffset] == 's'
                && bytes[fieldNameOffset + 1] == 'i'
                && bytes[fieldNameOffset + 2] == 'z'
                && bytes[fieldNameOffset + 3] == 'e')
            {
                *size = strtoll(bytes + i + 1, NULL, 10);
            }
            else if ((i - fieldNameOffset == 5)
                     && bytes[fieldNameOffset] == 'c'
                     && bytes[fieldNameOffset + 1] == 'r'
                     && bytes[fieldNameOffset + 2] == 'c'
                     && bytes[fieldNameOffset + 3] == '3'
                     && bytes[fieldNameOffset + 4] == '2')
            {
                *crc32 = strtoll(bytes + i + 1, NULL, 16);
            }
        }
        else if (bytes[i] == ' ')
        {
            fieldNameOffset = i + 1;
        }
    }
}

static NSUInteger beginOfData(const char *bytes,
                              NSUInteger startOffset,
                              NSUInteger length,
                              NSString **fileName,
                              NSUInteger *part,
                              NSUInteger *startIncludingHeader)
{
    NSUInteger offset = startOffset;
    while (offset < length)
    {
        offset = scanForPair(bytes, offset, length);
        if (offset < length - 7)
        {
            if (bytes[offset + 2] == 'b'
                && bytes[offset + 3] == 'e'
                && bytes[offset + 4] == 'g'
                && bytes[offset + 5] == 'i'
                && bytes[offset + 6] == 'n'
                && bytes[offset + 7] == ' ')
            {
                NSUInteger next = scanForNextLine(bytes, offset + 8, length);
                NSString *thisFileName;
                NSUInteger thisPart = 0;
                scanForBeginFields(bytes, offset + 8, next - 2, &thisFileName, &thisPart);
                
                // Is there a "=ypart" line?
                if (thisPart)
                {
                    next = scanForNextLine(bytes, next, length);
                }
                
                if (fileName)
                    *fileName = thisFileName;

                if (part)
                    *part = thisPart;
                
                if (startIncludingHeader)
                    *startIncludingHeader = offset;

                return next;
            }
        }
    }
    return NSUIntegerMax;
}

static NSUInteger endOfData(const char *bytes,
                            NSUInteger startOffset,
                            NSUInteger length,
                            NSUInteger *size,
                            NSUInteger *crc32,
                            NSUInteger *endIncludingTail)
{
    NSUInteger offset = startOffset;
    while (offset < length)
    {
        offset = scanForPair(bytes, offset, length);
        if (offset < length - 5)
        {
            if (bytes[offset + 2] == 'e'
                && bytes[offset + 3] == 'n'
                && bytes[offset + 4] == 'd'
                && bytes[offset + 5] == ' ')
            {
                NSUInteger next = scanForNextLine(bytes, offset + 5, length);
                scanForEndFields(bytes, offset + 5, next - 2, size, crc32);
                
                *endIncludingTail = next;
                
                return offset;
            }
        }
    }
    return NSUIntegerMax;
}

@implementation YEncDecoder

@synthesize encodedRange;
@synthesize fileName;
@synthesize size;
@synthesize CRC32;

+ (BOOL)containsYEncData:(NSData *)data
{
    const char *bytes = data.bytes;
    NSUInteger length = data.length;
    
    if (length < 9)
        return NO;

    if (beginOfData(bytes, 0, length, NULL, NULL, NULL) != NSUIntegerMax)
        return YES;

    return NO;
}

- (id)initWithData:(NSData *)encodedData
{
    self = [super init];
    if (self)
    {
        data = encodedData;
    }
    return self;
}

- (NSData *)decode
{
    NSMutableData *decodedData = nil;
    const char *bytes = data.bytes;
    NSUInteger length = data.length;
    NSUInteger beginOfBlock = 0;
    NSUInteger endOfBlock = 0;
    
    fileName = nil;
    part = 0;

    NSString *tempFileName;
    begin = beginOfData(bytes, 0, length, &tempFileName, &part, &beginOfBlock);
    fileName = tempFileName;
    if (begin < NSUIntegerMax)
    {
        end = endOfData(bytes, begin, length, &size, &CRC32, &endOfBlock);
        if (end < NSUIntegerMax)
        {
            NSLog(@"begin: %d, end: %d", begin, end);

            // Determine the range of the encoded data, including the header and footer
            encodedRange = NSMakeRange(beginOfBlock, endOfBlock - beginOfBlock);

            decodedData = [NSMutableData dataWithCapacity:length];
            BOOL newLine = YES;
            char output;
            for (NSUInteger i = begin; i < end; ++i)
            {
                if (bytes[i] == 10)
                {
                    newLine = YES;
                    continue;
                }
                else if (bytes[i] == 13)
                {
                    newLine = YES;
                    continue;
                }
                else if (newLine && bytes[i] == '.')
                {
                    // Skip any '.' that appear at the beginning of a line
                    // (it will be doubled-up)
                    newLine = NO;
                    continue;
                }
                else if (bytes[i] == '=')
                {
                    output = bytes[i + 1] - 64;
                    ++i;
                    output = output - 42;
                }
                else
                    output = bytes[i] - 42;
                [decodedData appendBytes:&output length:1];
                newLine = NO;
            }
        }
        else
        {
            begin = 0;
            end = 0;
        }
    }
    else
    {
        begin = 0;
        end = 0;
    }
    
    return decodedData;
}

@end
