//
//  DownloadArticlesTask.h
//  Network News
//
//  Created by David Schweinsberg on 21/12/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import "Task.h"

extern NSString *ArticleBytesReceivedNotification;
extern NSString *ArticleDownloadedNotification;
extern NSString *AllArticlesDownloadedNotification;
extern NSString *ArticleUnavailableNotification;

@class ArticlePart;
@class ArticlePartContent;

@interface DownloadArticlesTask : Task
{
    NSArray *articleParts;
    NSUInteger partIndex;
    ArticlePart *articlePart;
    ArticlePartContent *articlePartContent;
}

@property(nonatomic, retain, readonly) ArticlePart *articlePart;

@property(nonatomic, retain, readonly) ArticlePartContent *articlePartContent;

- (id)initWithConnection:(NNConnection *)aConnection
            articleParts:(NSArray *)parts;

@end
