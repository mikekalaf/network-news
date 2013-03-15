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

NSString *FetchArticleCompletedNotification = @"FetchArticleCompletedNotification";

@interface FetchArticleOperation ()
{
    NewsConnectionPool *_connectionPool;
    NSString *_messageID;
    BOOL _bodyOnly;
}

@end

@implementation FetchArticleOperation

- (id)initWithConnectionPool:(NewsConnectionPool *)connectionPool
                   messageID:(NSString *)messageID
                    bodyOnly:(BOOL)bodyOnly
{
    self = [super init];
    if (self)
    {
        _connectionPool = connectionPool;
        _messageID = messageID;
        _bodyOnly = bodyOnly;
    }
    return self;
}

- (void)main
{
    @try
    {
        // TODO: We need a way of tracking the number of bytes loaded so we can
        // show progress to the user. Probably a notification coming out of
        // the connection.
        NewsConnection *newsConnection = [_connectionPool dequeueConnection];
        NewsResponse *response;
        if (_bodyOnly)
            response = [newsConnection bodyWithMessageID:_messageID];
        else
            response = [newsConnection articleWithMessageID:_messageID];

        if ([response statusCode] == 220 || [response statusCode] == 222)
        {
            // Truncate the data, removing the terminating '.'
            // TODO Properly escape the data, removing escaped '.'
            //articlePartContent.data.length = articlePartContent.data.length - 3;

            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:FetchArticleCompletedNotification
                              object:self
                            userInfo:@{
             @"statusCode": [NSNumber numberWithInteger:[response statusCode]],
             @"messageID": _messageID,
             @"data": [response data]}];
        }
        else if ([response statusCode] == 430)
        {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:FetchArticleCompletedNotification
                              object:self
                            userInfo:@{@"statusCode": [NSNumber numberWithInteger:[response statusCode]]}];
        }
    }
    @catch (NSException *exception)
    {
    }
    @finally
    {
    }
}

@end
