//
//  ThreadIterator.h
//  Network News
//
//  Created by David Schweinsberg on 21/02/11.
//  Copyright 2011 David Schweinsberg. All rights reserved.
//

#import "ArticleViewController.h"
#import <Foundation/Foundation.h>

@interface ThreadIterator : NSObject <ArticleSource> {
  NSArray *threads;
  NSArray *articleCounts;
  NSUInteger totalCount;
}

- (instancetype)initWithThreads:(NSArray *)threadsArray
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

- (NSInteger)articleIndexOfThreadIndex:(NSUInteger)threadIndex;

- (NSInteger)threadIndexOfArticleIndex:(NSUInteger)articleIndex;

@end
