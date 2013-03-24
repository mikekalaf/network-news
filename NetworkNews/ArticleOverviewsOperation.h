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

typedef enum
{
    ArticleOverviewsLatest,
    ArticleOverviewsMore
} ArticleOverviewsMode;

typedef enum {
    ArticleOverviewsUndefined,
    ArticleOverviewsFailed,
    ArticleOverviewsComplete,
    ArticleOverviewsNoSuchGroup
} ArticleOverviewsStatus;

@interface ArticleOverviewsOperation : NSOperation

@property (nonatomic, readonly) GroupStore *groupStore;
@property (nonatomic, readonly) ArticleOverviewsMode mode;
@property (nonatomic, readonly) NSUInteger maxArticleCount;
@property (nonatomic, readonly) ArticleOverviewsStatus status;

- (id)initWithConnectionPool:(NewsConnectionPool *)connectionPool
                  groupStore:(GroupStore *)groupStore
                        mode:(ArticleOverviewsMode)mode
             maxArticleCount:(NSUInteger)maxArticleCount;

@end
