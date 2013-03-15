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

- (id)initWithConnectionPool:(NewsConnectionPool *)connectionPool wildmat:(NSString *)wildmat;

@end
