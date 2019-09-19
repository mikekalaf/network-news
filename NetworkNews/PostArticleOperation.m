//
//  PostArticleOperation.m
//  NetworkNews
//
//  Created by David Schweinsberg on 24/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "PostArticleOperation.h"
#import "NewsConnection.h"
#import "NewsConnectionPool.h"
#import "NewsResponse.h"

NSString *PostArticleCompletedNotification =
    @"PostArticleCompletedNotification";

@interface PostArticleOperation () {
  NewsConnectionPool *_connectionPool;
  NSData *_data;
}

@end

@implementation PostArticleOperation

- (instancetype)initWithConnectionPool:(NewsConnectionPool *)connectionPool
                                  data:(NSData *)data {
  self = [super init];
  if (self) {
    _connectionPool = connectionPool;
    _data = data;
  }
  return self;
}

- (void)main {
  @try {
    // Fetch the article from the article store
    NewsConnection *newsConnection = [_connectionPool dequeueConnection];

    NewsResponse *response = [newsConnection postData:_data];
    if (response.statusCode == 240) {
      // Article received
    } else if (response.statusCode == 440) {
      // Posting not permitted
    } else if (response.statusCode == 441) {
      // Posting failed
    }
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:PostArticleCompletedNotification
                      object:self
                    userInfo:@{
                      @"statusCode" : @(response.statusCode),
                      @"response" : response.string,
                    }];

    [_connectionPool enqueueConnection:newsConnection];
  } @catch (NSException *exception) {
  } @finally {
  }
}

@end
