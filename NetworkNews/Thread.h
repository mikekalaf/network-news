//
//  Thread.h
//  Network News
//
//  Created by David Schweinsberg on 20/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(unsigned int, ThreadType) { ThreadTypeMessage, ThreadTypeFile };

@class Article;
@class NNNewsrc;

@interface Thread : NSObject //<NSCoding>
{
  NSString *subject;
  NSString *initialAuthor;
  NSDate *earliestDate;
  NSDate *latestDate;
  NSMutableArray *articles;
  NSArray *sortedArticles;
  BOOL sorted;
  NSString *messageID;
  ThreadType threadType;
}

@property(nonatomic, copy) NSString *subject;
@property(nonatomic, copy) NSString *initialAuthor;
@property(nonatomic, retain) NSDate *earliestDate;
@property(nonatomic, retain) NSDate *latestDate;
@property(nonatomic, retain, readonly) NSMutableArray *articles;
@property(nonatomic, retain, readonly) NSArray *sortedArticles;
@property(nonatomic, readonly) BOOL hasAllParts;
@property(nonatomic) BOOL sorted;
@property(nonatomic, copy) NSString *messageID;
@property(nonatomic) ThreadType threadType;

- (instancetype)initWithArticle:(Article *)article;

@end
