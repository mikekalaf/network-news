//
//  DownloadArticleOverviewsTask.h
//  Network News
//
//  Created by David Schweinsberg on 11/12/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import "Task.h"
#import <CoreData/CoreData.h>

extern NSString *ArticleOverviewsDownloadedNotification;
extern NSString *NoSuchGroupNotification;

@class Group;
@class EncodedWordDecoder;

typedef enum
{
    DownloadArticleOverviewsTaskLatest,
    DownloadArticleOverviewsTaskMore
} DownloadArticleOverviewsTaskMode;

@interface DownloadArticleOverviewsTask : Task
{
    DownloadArticleOverviewsTaskMode downloadMode;
    NSUInteger maxArticleCount;
    NSRange articleRange;
    NSManagedObjectContext *context;
    NSEntityDescription *articleEntity;
    NSEntityDescription *articlePartEntity;
    NSMutableString *partialLine;
    NSUInteger linesRead;
    Group *group;
    NSMutableDictionary *placeholders;
    EncodedWordDecoder *encodedWordDecoder;
}

- (id)initWithConnection:(NNConnection *)aConnection
    managedObjectContext:(NSManagedObjectContext *)aContext
                   group:(Group *)aGroup
                    mode:(DownloadArticleOverviewsTaskMode)mode
         maxArticleCount:(NSUInteger)aMaxArticleCount;

@end
