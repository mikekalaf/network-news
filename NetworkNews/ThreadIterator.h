//
//  ThreadIterator.h
//  Network News
//
//  Created by David Schweinsberg on 21/02/11.
//  Copyright 2011 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArticleViewController.h"

@interface ThreadIterator : NSObject <ArticleSource>
{
    NSArray *threads;
    NSArray *articleCounts;
    NSUInteger totalCount;
}

- (id)initWithThreads:(NSArray *)threadsArray;

- (NSInteger)articleIndexOfThreadIndex:(NSUInteger)threadIndex;

- (NSInteger)threadIndexOfArticleIndex:(NSUInteger)articleIndex;

@end
