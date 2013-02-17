//
//  Thread.h
//  Network News
//
//  Created by David Schweinsberg on 20/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

enum
{
    ReadStatusUnread,
    ReadStatusPartiallyRead,
    ReadStatusRead
};
typedef NSUInteger ReadStatus;

typedef enum
{
    ThreadTypeMessage,
    ThreadTypeFile
} ThreadType;

@class Article;

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
@property(nonatomic, readonly) ReadStatus readStatus;
@property(nonatomic, readonly) BOOL hasAllParts;
@property(nonatomic) BOOL sorted;
@property(nonatomic, copy) NSString *messageID;
@property(nonatomic) ThreadType threadType;

- (id)initWithArticle:(Article *)article;

@end
