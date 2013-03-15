//
//  NewsConnectionPool.h
//  NetworkNews
//
//  Created by David Schweinsberg on 10/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NewsAccount;
@class NewsConnection;

@interface NewsConnectionPool : NSObject

- (id)initWithAccount:(NewsAccount *)account;

- (NewsConnection *)dequeueConnection;
- (void)enqueueConnection:(NewsConnection *)connection;

@end
