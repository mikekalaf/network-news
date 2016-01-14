//
//  ArticleOverviewsOperation.h
//  NetworkNews
//
//  Created by David Schweinsberg on 10/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NewsConnectionPool;
@class GroupStore;

typedef NS_ENUM(unsigned int, ArticleOverviewsMode)
{
    ArticleOverviewsLatest,
    ArticleOverviewsMore
};

typedef NS_ENUM(unsigned int, ArticleOverviewsStatus) {
    ArticleOverviewsUndefined,
    ArticleOverviewsFailed,
    ArticleOverviewsComplete,
    ArticleOverviewsNoSuchGroup
};

@interface ArticleOverviewsOperation : NSOperation

@property (nonatomic, readonly) GroupStore *groupStore;
@property (nonatomic, readonly) ArticleOverviewsMode mode;
@property (nonatomic, readonly) NSUInteger maxArticleCount;
@property (nonatomic, readonly) ArticleOverviewsStatus status;

- (instancetype)initWithConnectionPool:(NewsConnectionPool *)connectionPool
                  groupStore:(GroupStore *)groupStore
                        mode:(ArticleOverviewsMode)mode
             maxArticleCount:(NSUInteger)maxArticleCount NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@end
