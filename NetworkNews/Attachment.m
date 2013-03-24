//
//  Attachment.m
//  Network News
//
//  Created by David Schweinsberg on 4/03/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "Attachment.h"
#import "ContentType.h"
#import "YEncDecoder.h"
#import "UUDecoder.h"
#import "NNBase64Decoder.h"
#import "NSData+NewsAdditions.h"

@implementation Attachment

-   (id)initWithBodyData:(NSData *)bodyData
             contentType:(ContentType *)contentType
 contentTransferEncoding:(NSString *)contentTransferEncoding
{
    self = [super init];
    if (self)
    {
        if ([[contentType mediaType] hasPrefix:@"image"])
        {
            if ([contentTransferEncoding caseInsensitiveCompare:@"base64"] == NSOrderedSame)
            {
                NNBase64Decoder *decoder = [[NNBase64Decoder alloc] initWithData:bodyData];
                _data = [decoder decode];
                _fileName = [contentType name];
                _rangeInArticleData = NSMakeRange(0, [bodyData length]);

                NSLog(@"base64 Filename: %@", _fileName);
            }
        }
        else if ([YEncDecoder containsYEncData:bodyData])
        {
            YEncDecoder *decoder = [[YEncDecoder alloc] initWithData:bodyData];
            _data = [decoder decode];
            if (_data)
            {
                _fileName = [[decoder fileName] copy];
                _rangeInArticleData = [decoder encodedRange];

                NSLog(@"yEnc Filename: %@", _fileName);

                // Check the checksum
                if (decoder.CRC32)
                {
                    NSUInteger dataCRC32 = [_data CRC32];
                    if ([decoder CRC32] != dataCRC32)
                        NSLog(@"Reported CRC32: %x, Calculated CRC32: %x",
                              [decoder CRC32],
                              dataCRC32);
                }
            }
        }
        else if ([UUDecoder containsUUEncodedData:bodyData])
        {
            UUDecoder *decoder = [[UUDecoder alloc] initWithData:bodyData];
            _data = [decoder decode];
            if (_data)
            {
                _fileName = [[decoder fileName] copy];
                _rangeInArticleData = [decoder encodedRange];
                
                NSLog(@"uuencode Filename: %@", [decoder fileName]);
            }
        }
    }

    if (_data == nil)
    {
        return nil;
    }
    return self;
}

@end
