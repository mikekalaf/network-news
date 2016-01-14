//
//  GroupListSearchOperation.h
//  NetworkNews
//
//  Created by David Schweinsberg on 9/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NewsConnectionPool;

@interface GroupListSearchOperation : NSOperation

@property(nonatomic, readonly) NSString *wildmat;
@property(nonatomic, readonly) NSArray *groups;

- (instancetype)initWithConnectionPool:(NewsConnectionPool *)connectionPool wildmat:(NSString *)wildmat NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@end
