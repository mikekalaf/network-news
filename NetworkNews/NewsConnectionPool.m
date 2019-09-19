//
//  NewsConnectionPool.m
//  NetworkNews
//
//  Created by David Schweinsberg on 10/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "NewsConnectionPool.h"
#import "NewsAccount.h"
#import "NewsConnection.h"
#import "UIApplication+NewsAdditions.h"

@interface NewsConnectionPool () {
  NSMutableArray *_connections;
}

@end

@implementation NewsConnectionPool

- (instancetype)initWithAccount:(NewsAccount *)account {
  self = [super init];
  if (self) {
    _account = account;
    _connections = [[NSMutableArray alloc] init];
  }
  return self;
}

- (NewsConnection *)dequeueConnection {
  [[UIApplication sharedApplication] showNetworkActivityIndicator];

  NewsConnection *newsConnection = nil;

  if (_connections.count == 0) {
    newsConnection = [[NewsConnection alloc] initWithHost:_account.hostName
                                                     port:_account.port
                                                 isSecure:_account.secure];
    [newsConnection loginWithUser:_account.userName password:_account.password];
  } else {
    @synchronized(self) {
      newsConnection = _connections.lastObject;
      [_connections removeLastObject];
    }
  }

  if (newsConnection == nil)
    [[UIApplication sharedApplication] hideNetworkActivityIndicator];

  return newsConnection;
}

- (void)enqueueConnection:(NewsConnection *)connection {
  if (connection != nil) {
    @synchronized(self) {
      [_connections addObject:connection];
    }
  }
  [[UIApplication sharedApplication] hideNetworkActivityIndicator];
}

- (void)closeAllConnections {
  @synchronized(self) {
    [_connections removeAllObjects];
  }
}

@end
