//
//  Attachment.m
//  Network News
//
//  Created by David Schweinsberg on 4/03/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "Attachment.h"
#import "ArticlePartContent.h"
#import "YEncDecoder.h"
#import "UUDecoder.h"
#import "NSData+NewsAdditions.h"

@implementation Attachment

@synthesize fileName;
@synthesize data;
@synthesize rangeInArticleData;

- (id)initWithContent:(ArticlePartContent *)content
{
    self = [super init];
    if (self)
    {
        NSData *bodyData = content.bodyData;

        if ([YEncDecoder containsYEncData:bodyData])
        {
            YEncDecoder *decoder = [[YEncDecoder alloc] initWithData:bodyData];
            data = [decoder decode];
            if (data)
            {
                fileName = [decoder.fileName copy];
                rangeInArticleData = decoder.encodedRange;

                NSLog(@"yEnc Filename: %@", fileName);

                // Check the checksum
                if (decoder.CRC32)
                {
                    NSUInteger dataCRC32 = data.CRC32;
                    if (decoder.CRC32 != dataCRC32)
                        NSLog(@"Reported CRC32: %x, Calculated CRC32: %x",
                              decoder.CRC32,
                              dataCRC32);
                }
            }
        }
        else if ([UUDecoder containsUUEncodedData:bodyData])
        {
            UUDecoder *decoder = [[UUDecoder alloc] initWithData:bodyData];
            data = [decoder decode];
            if (data)
            {
                fileName = [decoder.fileName copy];
                rangeInArticleData = decoder.encodedRange;
                
                NSLog(@"uuencode Filename: %@", decoder.fileName);
            }
        }
    }

    if (data == nil)
    {
        return nil;
    }
    return self;
}

@end
