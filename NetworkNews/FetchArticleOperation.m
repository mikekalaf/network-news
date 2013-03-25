//
//  FetchArticleOperation.m
//  NetworkNews
//
//  Created by David Schweinsberg on 15/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "FetchArticleOperation.h"
#import "NewsConnection.h"
#import "NewsResponse.h"
#import "NewsConnectionPool.h"
#import "Attachment.h"
#import "NNHeaderParser.h"
#import "NNHeaderEntry.h"
#import "ContentType.h"
#import "Article.h"
#import "NSString+NewsAdditions.h"
#import "QuotedPrintableDecoder.h"

NSString *FetchArticleCompletedNotification = @"FetchArticleCompletedNotification";

@interface FetchArticleOperation ()
{
    NewsConnectionPool *_connectionPool;
    NSString *_messageID;
    NSUInteger _partNumber;
    NSUInteger _totalPartCount;
    NSArray *_headEntries;
    NSRange _headRange;
    NSRange _bodyRange;
    NSURL *_cacheURL;
    BOOL _final;
    //Article *_article;
    void (^_progressBlock)(NSUInteger bytesReceived);
}

@end

@implementation FetchArticleOperation

- (id)initWithConnectionPool:(NewsConnectionPool *)connectionPool
                   messageID:(NSString *)messageID
                  partNumber:(NSUInteger)partNumber
              totalPartCount:(NSUInteger)totalPartCount
                    cacheURL:(NSURL *)cacheURL
                    progress:(void (^)(NSUInteger bytesReceived))progressBlock
{
    self = [super init];
    if (self)
    {
        _connectionPool = connectionPool;
        _messageID = messageID;
        _partNumber = partNumber;
        _totalPartCount = totalPartCount;
        _cacheURL = cacheURL;
        _progressBlock = progressBlock;
    }
    return self;
}

- (void)main
{
    @try
    {
        // Fetch the article from the article store
        NewsConnection *newsConnection = [_connectionPool dequeueConnection];

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(bytesReceived:)
                   name:NewsConnectionBytesReceivedNotification
                 object:newsConnection];

        NewsResponse *response;
        if (_partNumber > 1)
            response = [newsConnection bodyWithMessageID:_messageID];
        else
            response = [newsConnection articleWithMessageID:_messageID];

        if ([response statusCode] == 220 || [response statusCode] == 222)
        {
            // TODO Properly escape the data, removing escaped '.'

            [self processHead:[response data]];

            [self processBody:[response data]];

            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:FetchArticleCompletedNotification
                              object:self
                            userInfo:@{
             @"statusCode": @([response statusCode]),
             @"messageID": _messageID,
             @"partNumber": @(_partNumber),
             @"totalPartCount": @(_totalPartCount)}];
        }
        else if ([response statusCode] == 430)
        {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:FetchArticleCompletedNotification
                              object:self
                            userInfo:@{@"statusCode": @([response statusCode])}];
        }

        [nc removeObserver:self];
        [_connectionPool enqueueConnection:newsConnection];
    }
    @catch (NSException *exception)
    {
    }
    @finally
    {
    }
}

- (void)bytesReceived:(NSNotification *)notification
{
    _progressBlock([[notification userInfo][@"byteCount"] integerValue]);
}

- (NSString *)headerValueWithName:(NSString *)name
{
    for (NNHeaderEntry *entry in _headEntries)
        if ([entry.name caseInsensitiveCompare:name] == NSOrderedSame)
            return entry.value;
    return nil;
}

- (ContentType *)contentType
{
    ContentType *contentType = nil;
    NSString *contentTypeValue = [self headerValueWithName:@"Content-Type"];
    if (contentTypeValue)
        contentType = [[ContentType alloc] initWithString:contentTypeValue];
    return contentType;
}

- (NSURL *)cacheURLForMessageID:(NSString *)messageID
                          order:(NSUInteger)order
                      extension:(NSString *)extension
{
    NSString *fileName = [NSString stringWithFormat:@"%@.%03d", [messageID messageIDFileName], order];
    return [_cacheURL URLByAppendingPathComponent:[fileName stringByAppendingPathExtension:extension]];
}

- (void)processHead:(NSData *)data
{
    // Truncate the body data, removing the terminating '.', by subtracting 3
    // from the body length

    if (_partNumber > 1)
    {
        _headRange = NSMakeRange(0, 0);
        _bodyRange = NSMakeRange(0, [data length] - 3);
    }
    else
    {
        // Initialise the head and body ranges
        NNHeaderParser *hp = [[NNHeaderParser alloc] initWithData:data];
        _headEntries = hp.entries;

        _headRange = NSMakeRange(0, hp.length);
        _bodyRange = NSMakeRange(hp.length, data.length - hp.length - 3);
    }
}

- (void)processBody:(NSData *)data
{
    NSData *bodyData = [data subdataWithRange:_bodyRange];

    NSString *contentTransferEncoding = [self headerValueWithName:@"Content-Transfer-Encoding"];

    Attachment *attachment = [[Attachment alloc] initWithBodyData:bodyData
                                                      contentType:[self contentType]
                                          contentTransferEncoding:contentTransferEncoding];
    if (attachment)
    {
        if (_partNumber == 1)
        {
            // Grab the initial text in the first part
            // Calculate the range of the header text and the body text up to
            // the attachment

            // Cache this initial text
            NSURL *mIdHeadURL = [self cacheURLForMessageID:_messageID
                                                     order:0
                                                 extension:@"txt"];
            NSData *headData = [data subdataWithRange:_headRange];
            [headData writeToURL:mIdHeadURL atomically:NO];

            // Only cache the top text if there is actually any
            if ([attachment rangeInArticleData].location > 0)
            {
                NSRange range = NSMakeRange(0, [attachment rangeInArticleData].location);
                NSData *bodyTextDataTop = [bodyData subdataWithRange:range];

                NSURL *mIdURL = [self cacheURLForMessageID:_messageID
                                                     order:1
                                                 extension:@"txt"];
                [bodyTextDataTop writeToURL:mIdURL atomically:NO];
            }

            // Do we really need to do the following? Surely we can determine
            // what the attachment filename would be, especially if it incorporates
            // the message ID

//            // Note the attachment filename
//            NSURL *attachmentURL = [self cacheURLForMessageID:_messageID
//                                                    extension:[[attachment fileName] pathExtension]];
//            [_article setAttachmentFileName:[attachment fileName]];
//
//            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//            [appDelegate.activeCoreDataStack save];
        }

        if (_partNumber == _totalPartCount)
        {
            // Grab the trailing text in the last part (this could still be
            // the first part)

            NSUInteger end = NSMaxRange([attachment rangeInArticleData]);
            NSRange range = NSMakeRange(end, [bodyData length] - end);

            // Only cache it if there is actual content
            if (range.length > 0)
            {
                NSData *bodyTextDataBottom = [bodyData subdataWithRange:range];

                // Cache this trailing text
                NSURL *mIdURL = [self cacheURLForMessageID:_messageID
                                                     order:3
                                                 extension:@"txt"];
                [bodyTextDataBottom writeToURL:mIdURL atomically:NO];
            }
        }

        // TODO: The following will fail when multi-part articles fail to specify
        // the filename

        NSURL *attachmentURL = [self cacheURLForMessageID:_messageID
                                                    order:2
                                                extension:[[attachment fileName] pathExtension]];
        if (_partNumber == 1)
        {
            // Create the file
            NSError *error;
            if ([[attachment data] writeToURL:attachmentURL options:0 error:&error] == NO)
            {
                NSLog(@"Error in caching file: %@", [error description]);
            }
        }
        else
        {
            // Append to the end of the file
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingToURL:attachmentURL error:NULL];
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[attachment data]];
            [fileHandle closeFile];
        }
    }
    else
    {
        // This is text only
        if (_partNumber == 1)
        {
            BOOL quotedPrintable = [QuotedPrintableDecoder isQuotedPrintable:_headEntries];

            if (quotedPrintable)
            {
                QuotedPrintableDecoder *quotedPrintableDecoder = [[QuotedPrintableDecoder alloc] init];
                bodyData = [quotedPrintableDecoder decodeData:bodyData];
            }

            // Save to the cache
            NSURL *mIdHeadURL = [self cacheURLForMessageID:_messageID
                                                     order:0
                                                 extension:@"txt"];
            NSData *headData = [data subdataWithRange:_headRange];
            [headData writeToURL:mIdHeadURL atomically:NO];

            NSURL *mIdURL = [self cacheURLForMessageID:_messageID
                                                 order:1
                                             extension:@"txt"];
            [bodyData writeToURL:mIdURL atomically:NO];
            
            NSLog(@"cache path: %@", mIdURL);
        }
    }
}

@end
