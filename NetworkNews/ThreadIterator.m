//
//  ThreadIterator.m
//  Network News
//
//  Created by David Schweinsberg on 21/02/11.
//  Copyright 2011 David Schweinsberg. All rights reserved.
//

#import "ThreadIterator.h"
#import "Thread.h"

@implementation ThreadIterator

- (instancetype)initWithThreads:(NSArray *)threadsArray
{
    self = [super init];
    if (self)
    {
        threads = threadsArray;

        // Count the number of articles in each thread
        NSMutableArray *counts = [NSMutableArray array];
        for (Thread *thread in threads)
        {
            NSInteger count = thread.articles.count;
            totalCount += count;
            [counts addObject:@(count)];
        }
        articleCounts = [counts copy];
    }
    return self;
}

- (NSInteger)articleIndexOfThreadIndex:(NSUInteger)threadIndex
{
    NSInteger runningCount = 0;
    for (NSUInteger i = 0; i < threadIndex; ++i)
        runningCount += [articleCounts[i] integerValue];
    return runningCount;
}

- (NSInteger)threadIndexOfArticleIndex:(NSUInteger)articleIndex
{
    NSInteger threadIndex = 0;
    NSInteger runningCount = 0;
    for (NSNumber *articleCount in articleCounts)
    {
        runningCount += articleCount.integerValue;
        if (runningCount > articleIndex)
            return threadIndex;
        ++threadIndex;
    }
    return 0;
}

#pragma mark -
#pragma mark ArticleSource Methods

- (NSUInteger)articleCount
{
    return totalCount;
}

- (Article *)articleAtIndex:(NSUInteger)index
{
    NSUInteger runningCount = 0;
    for (Thread *thread in threads)
    {
        NSUInteger count = thread.articles.count;
        if (runningCount + count > index)
            return thread.sortedArticles[index - runningCount];
        runningCount += count;
    }
    return nil;
}

@end
