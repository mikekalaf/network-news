//
//  UUDecoder.m
//  Network News
//
//  Created by David Schweinsberg on 1/03/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "UUDecoder.h"

// These functions depend on working with data that still retains the message
// headers, and therefore the "begin <mode> <filename>" will never occur on the
// first line

static NSUInteger endOfLine(const char *bytes, NSUInteger startOffset, NSUInteger length)
{
    for (NSUInteger i = startOffset; i < length - 2; ++i)
    {
        if (bytes[i] == 13 && bytes[i + 1] == 10)
            return i - startOffset;
        else if (bytes[i] == 10)
            return i - startOffset;
    }
    return 0;
}

static NSUInteger scanForNextLine(const char *bytes, NSUInteger startOffset, NSUInteger length)
{
    for (NSUInteger i = startOffset; i < length - 2; ++i)
    {
        if (bytes[i] == 13 && bytes[i + 1] == 10)
            return i + 2;
        else if (bytes[i] == 10)
            return i + 1;
    }
    return NSUIntegerMax;
}

static NSUInteger scanForUuencodedData(const char *bytes,
                                       NSUInteger startOffset,
                                       NSUInteger length,
                                       NSString **fileName,
                                       NSUInteger *startIncludingHeader)
{
    if (length < 11)
        return NSUIntegerMax;

    NSUInteger candidateStart = 0;
    NSUInteger linesOfValidData = 0;

    for (NSUInteger i = startOffset; i < length - 11; ++i)
    {
        if (bytes[i] == 'b'
            && bytes[i + 1] == 'e'
            && bytes[i + 2] == 'g'
            && bytes[i + 3] == 'i'
            && bytes[i + 4] == 'n'
            && bytes[i + 5] == ' '
            && isdigit(bytes[i + 6])
            && isdigit(bytes[i + 7])
            && isdigit(bytes[i + 8])
            && bytes[i + 9] == ' ')
        {
            NSUInteger next = scanForNextLine(bytes, i + 10, length);
            if (fileName)
            {
                NSUInteger fileNamelen = endOfLine(bytes, i + 10, length);
                *fileName = [[NSString alloc] initWithBytes:bytes + i + 10
                                                     length:fileNamelen
                                                   encoding:NSASCIIStringEncoding];
            }
            
            if (startIncludingHeader)
                *startIncludingHeader = i;

            return next;
        }
        else if (bytes[i] == 13
                 && bytes[i + 1] == 10
                 && bytes[i + 2] == 'b'
                 && bytes[i + 3] == 'e'
                 && bytes[i + 4] == 'g'
                 && bytes[i + 5] == 'i'
                 && bytes[i + 6] == 'n'
                 && bytes[i + 7] == ' '
                 && isdigit(bytes[i + 8])
                 && isdigit(bytes[i + 9])
                 && isdigit(bytes[i + 10])
                 && bytes[i + 11] == ' ')
        {
            NSUInteger next = scanForNextLine(bytes, i + 12, length);
            if (fileName)
            {
                NSUInteger fileNamelen = endOfLine(bytes, i + 12, length);
                *fileName = [[NSString alloc] initWithBytes:bytes + i + 12
                                                     length:fileNamelen
                                                   encoding:NSASCIIStringEncoding];
            }
            
            if (startIncludingHeader)
                *startIncludingHeader = i + 2;
            
            return next;
        }
        else if (bytes[i] == 13 && bytes[i + 1] == 10)
        {
            // Is the first column in the data length range?
            NSUInteger byteCount;
            if (bytes[i + 2] == '`')
                byteCount = 0;
            else
                byteCount = bytes[i + 2] - 32;
            
            if (byteCount > 45)
            {
                linesOfValidData = 0;
                continue;
            }
            
            NSUInteger encodingLen = endOfLine(bytes, i + 3, length);
            
            // Is the encoded data length a multiple of 4?
            if (encodingLen % 4)
            {
                linesOfValidData = 0;
                continue;
            }
            
            // Does the decoded length equal the byteCount?
//            if (encodingLen / 4 * 3 == byteCount)
//                return i + 2;

            if (encodingLen / 4 * 3 == byteCount)
            {
                if (linesOfValidData == 0)
                    candidateStart = i + 2;

                // Return the start of data if we have 8 lines
                // (7 plus this one) of it
                if (linesOfValidData == 7)
                {
                    if (startIncludingHeader)
                        *startIncludingHeader = candidateStart;
                    return candidateStart;
                }
                
                ++linesOfValidData;
            }

            // Advance index to next line
            i += 2;
            i += encodingLen;
            // i will increment by one more because of the for loop
        }
        else
        {
            linesOfValidData = 0;
        }
    }
    return NSUIntegerMax;
}

static NSUInteger stopOfData(const char *bytes,
                             NSUInteger startOffset,
                             NSUInteger length,
                             NSUInteger *endIncludingTail)
{
    for (NSUInteger i = startOffset; i < length - 6; ++i)
    {
        if (bytes[i] == 13
            && bytes[i + 1] == 10
            && bytes[i + 2] == 'e'
            && bytes[i + 3] == 'n'
            && bytes[i + 4] == 'd'
            && bytes[i + 5] == 13
            && bytes[i + 6] == 10)
        {
            if (endIncludingTail)
                *endIncludingTail = i + 6;
            return i + 1;
        }
    }

    // Scan again, but look for only LFs
    for (NSUInteger i = startOffset; i < length - 4; ++i)
    {
        if (bytes[i] == 10
            && bytes[i + 1] == 'e'
            && bytes[i + 2] == 'n'
            && bytes[i + 3] == 'd'
            && bytes[i + 4] == 10)
        {
            if (endIncludingTail)
                *endIncludingTail = i + 4;
            return i;
        }
    }

    if (endIncludingTail)
        *endIncludingTail = length;

    return length;
}

@implementation UUDecoder

@synthesize fileName;
@synthesize encodedRange;

+ (BOOL)containsUUEncodedData:(NSData *)data
{
    const char *bytes = data.bytes;
    NSUInteger length = data.length;
    
    if (scanForUuencodedData(bytes, 0, length, NULL, NULL) != NSUIntegerMax)
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

    NSString *scanFilename;

    begin = scanForUuencodedData(bytes, 0, length, &scanFilename, &beginOfBlock);
    fileName = scanFilename;
    if (begin < NSUIntegerMax)
    {
        end = stopOfData(bytes, begin, length, &endOfBlock);
        if (end < NSUIntegerMax)
        {
            NSLog(@"begin: %d (%d), end: %d (%d)", begin, beginOfBlock, end, endOfBlock);
            
            // Determine the range of the encoded data, including the header and footer
            encodedRange = NSMakeRange(beginOfBlock, endOfBlock - beginOfBlock);
            
            decodedData = [NSMutableData dataWithCapacity:length];
            char buffer[45];
//            char testBuffer[60];
            int col = 0;
            int byteCount = 0;
            int bufIndex = 0;
            BOOL skipLine = NO;
            for (NSUInteger i = begin; i < end; ++i)
            {
                if (bytes[i] == 10 || bytes[i] == 13)
                {
                    if (byteCount > 0)
                    {
                        // bufIndex increments in multiples of three, as three
                        // bytes are packed at a time into four characters.
                        // byteCount represents the unpacked number of bytes.
                        if (byteCount <= bufIndex && bufIndex < byteCount + 3)
                        {
                            [decodedData appendBytes:buffer length:byteCount];
                        }
                        else
                        {
                            NSLog(@"Mismatched data in line whilst uudecoding (byteCount: %d, bufIndex: %d)", byteCount, bufIndex);
                            break;
                        }
                    }

                    col = 0;
                    bufIndex = 0;
                    byteCount = 0;
                    skipLine = NO;
//                    memset(testBuffer, 0, 60);
                    continue;
                }
                else if (skipLine)
                {
                    continue;
                }
                else if (col == 0)
                {
//                    testBuffer[col] = bytes[i];

                    if (bytes[i] == '`')
                        byteCount = 0;
                    else
                        byteCount = bytes[i] - 32;
                    ++col;
                    
                    // Is the byteCount in the valid range?
                    if (byteCount < 0 || byteCount > 45)
                    {
                        skipLine = YES;
                        NSLog(@"Skipping line whilst uudecoding");
                        break;
                    }
                }
                else
                {
                    if (bufIndex >= 45)
                    {
                        NSLog(@"Uudecoding line length exceeded");
                        
//                        NSString *str = [NSString stringWithCString:testBuffer length:60];
//                        NSLog(@"Line: %@", str);
                        
                        break;
                    }
                    else
                    {
//                        testBuffer[col] = bytes[i];
//                        testBuffer[col + 1] = bytes[i + 1];
//                        testBuffer[col + 2] = bytes[i + 2];
//                        testBuffer[col + 3] = bytes[i + 3];
                        
                        // 543210 54|3210 5432|10 543210
                        buffer[bufIndex] = ((bytes[i] - 32) << 2) | (((bytes[i + 1] - 32) & 63) >> 4);
                        buffer[bufIndex + 1] = ((bytes[i + 1] - 32) << 4) | (((bytes[i + 2] - 32) & 63) >> 2);
                        buffer[bufIndex + 2] = ((bytes[i + 2] - 32) << 6) | ((bytes[i + 3] - 32) & 63);

                        i += 3;
                        col += 4;
                        bufIndex += 3;
                    }
                }
            }
        }
    }
    
    return decodedData;
}

@end
