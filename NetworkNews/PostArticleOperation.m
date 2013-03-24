//
//  PostArticleOperation.m
//  NetworkNews
//
//  Created by David Schweinsberg on 24/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "PostArticleOperation.h"
#import "NewsConnectionPool.h"
#import "NewsConnection.h"
#import "NewsResponse.h"

@interface PostArticleOperation ()
{
    NewsConnectionPool *_connectionPool;
    NSData *_data;
}

@end

@implementation PostArticleOperation

- (id)initWithConnectionPool:(NewsConnectionPool *)connectionPool
                        data:(NSData *)data
{
    self = [super init];
    if (self)
    {
        _connectionPool = connectionPool;
        _data = data;
    }
    return self;
}

- (void)main
{
    @try
    {
        // Fetch the article from the article store
        NewsConnection *newsConnection = [_connectionPool dequeueConnection];

        NewsResponse *response = [newsConnection postData:_data];
        if ([response statusCode] == 240)
        {
            // Article received
        }
        else if ([response statusCode] == 440)
        {
            // Posting not permitted
        }
        else if ([response statusCode] == 441)
        {
            // Posting failed
        }

        [_connectionPool enqueueConnection:newsConnection];
    }
    @catch (NSException *exception)
    {
    }
    @finally
    {
    }
}

@end
