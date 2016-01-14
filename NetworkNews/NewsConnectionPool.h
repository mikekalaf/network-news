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

@property (nonatomic, readonly) NewsAccount *account;

- (instancetype)initWithAccount:(NewsAccount *)account NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@property (NS_NONATOMIC_IOSONLY, readonly, strong) NewsConnection *dequeueConnection;
- (void)enqueueConnection:(NewsConnection *)connection;

@end
