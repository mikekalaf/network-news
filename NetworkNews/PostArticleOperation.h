//
//  PostArticleOperation.h
//  NetworkNews
//
//  Created by David Schweinsberg on 24/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *PostArticleCompletedNotification;

@class NewsConnectionPool;

@interface PostArticleOperation : NSOperation

- (instancetype)initWithConnectionPool:(NewsConnectionPool *)connectionPool
                                  data:(NSData *)data NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@end
