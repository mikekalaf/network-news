//
//  NNHeaderParser.m
//  Network News
//
//  Created by David Schweinsberg on 8/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NNHeaderParser.h"
#import "NNHeaderEntry.h"

@interface NNHeaderParser ()
{
    NSData *data;
}

- (BOOL)needToUnfold;
- (void)unfold;
- (void)parseEntries;

@end

@implementation NNHeaderParser

- (instancetype)initWithData:(NSData *)articleData
{
    self = [super init];
    if (self)
    {
        // Scan the data for the division between header and body
        const char *bytes = articleData.bytes;
        NSUInteger articleLength = articleData.length;
        NSUInteger start = 0;
        for (NSUInteger i = 0; i < articleLength - 3; ++i)
        {
            // Step past the status line in the data
            if (start == 0 && bytes[i] == 13 && bytes[i + 1] == 10)
                start = i + 2;
            
            if (bytes[i] == 13
                && bytes[i + 1] == 10
                && bytes[i + 2] == 13
                && bytes[i + 3] == 10)
            {
                // Make a note of the length, because this may change if we
                // need to unfold header entries
                _length = i + 4;
                NSRange headRange = NSMakeRange(start, i - start + 2);
                data = [articleData subdataWithRange:headRange];
                [self unfold];
                [self parseEntries];
                break;
            }
        }
        
        if (!data)
        {
            return nil;
        }
    }
    return self;
}

- (BOOL)needToUnfold
{
    const char *bytes = data.bytes;
    NSUInteger articleLength = data.length;
    for (NSUInteger i = 0; i < articleLength - 2; ++i)
    {
        if (bytes[i] == 13
            && bytes[i + 1] == 10
            && (bytes[i + 2] == ' ' || bytes[i + 2] == '\t'))
        {
            return YES;
        }
    }
    return NO;
}

- (void)unfold
{
    if (![self needToUnfold])
        return;
    
    // Remove all the CRLF characters
    NSMutableData *mutableData = [NSMutableData dataWithCapacity:data.length];
    const char *bytes = data.bytes;
    NSUInteger articleLength = data.length;
    NSUInteger start = 0;
    NSUInteger i;
    for (i = 0; i < articleLength - 2; ++i)
    {
        if (bytes[i] == 13
            && bytes[i + 1] == 10
            && (bytes[i + 2] == ' ' || bytes[i + 2] == '\t'))
        {
            [mutableData appendBytes:bytes + start length:i - start];
            start = i + 2;
        }
    }
    [mutableData appendBytes:bytes + start length:i - start + 2];
    
    // Replace tabs with spaces
    char *mutableBytes = mutableData.mutableBytes;
    NSUInteger mutableLength = mutableData.length;
    for (i = 0; i < mutableLength; ++i)
        if (mutableBytes[i] == '\t')
            mutableBytes[i] = ' ';
    
    data = mutableData;
}

- (void)parseEntries
{
    NSMutableArray *mutableArray = [NSMutableArray array];
    const char *bytes = data.bytes;
    NSUInteger articleLength = data.length;
    NSUInteger divider = 0;
    NSUInteger start = 0;
    for (NSUInteger i = 0; i < articleLength - 1; ++i)
    {
        if (start >= divider
            && bytes[i] == ':'
            && (bytes[i + 1] == ' ' || bytes[i + 1] == '\t'))
        {
            // Note the divider between field name and value
            divider = i;
        }
        else if (bytes[i] == 13 && bytes[i + 1] == 10)
        {
            // We have a field
            NSString *name = [[NSString alloc] initWithBytes:bytes + start
                                                      length:divider - start
                                                    encoding:NSUTF8StringEncoding];
            if (!name)
                name = [[NSString alloc] initWithBytes:bytes + start
                                                length:divider - start
                                              encoding:NSISOLatin1StringEncoding];
            
            NSString *value = [[NSString alloc] initWithBytes:bytes + divider + 2
                                                       length:i - divider - 2
                                                     encoding:NSUTF8StringEncoding];
            if (!value)
                value = [[NSString alloc] initWithBytes:bytes + divider + 2
                                                 length:i - divider - 2
                                               encoding:NSISOLatin1StringEncoding];
            if (name && value)
            {
                NNHeaderEntry *entry = [[NNHeaderEntry alloc] initWithName:name
                                                                     value:value];
                [mutableArray addObject:entry];
            }

            start = i + 2;
        }
    }
    _entries = mutableArray;
}

@end
