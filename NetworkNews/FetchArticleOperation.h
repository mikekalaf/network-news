//
//  FetchArticleOperation.h
//  NetworkNews
//
//  Created by David Schweinsberg on 15/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *FetchArticleCompletedNotification;

@class NewsConnectionPool;

@interface FetchArticleOperation : NSOperation

- (id)initWithConnectionPool:(NewsConnectionPool *)connectionPool
                   messageID:(NSString *)messageID
                  partNumber:(NSUInteger)partNumber
              totalPartCount:(NSUInteger)totalPartCount
                    cacheURL:(NSURL *)cacheURL
                    progress:(void (^)(NSUInteger bytesReceived))progressBlock;

@end
