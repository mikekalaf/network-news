//
//  PostArticleOperation.h
//  NetworkNews
//
//  Created by David Schweinsberg on 24/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NewsConnectionPool;

@interface PostArticleOperation : NSOperation

- (id)initWithConnectionPool:(NewsConnectionPool *)connectionPool
                        data:(NSData *)data;

@end
