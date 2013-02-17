//
//  DownloadArticlesTask.m
//  Network News
//
//  Created by David Schweinsberg on 21/12/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import "DownloadArticlesTask.h"
#import "NNConnection.h"
#import "ArticlePart.h"
#import "ArticlePartContent.h"

NSString *ArticleBytesReceivedNotification = @"ArticleBytesReceivedNotification";
NSString *ArticleDownloadedNotification = @"ArticleDownloadedNotification";
NSString *AllArticlesDownloadedNotification = @"AllArticlesDownloadedNotification";
NSString *ArticleUnavailableNotification = @"ArticleUnavailableNotification";

@implementation DownloadArticlesTask

@synthesize articlePart;
@synthesize articlePartContent;

- (id)initWithConnection:(NNConnection *)aConnection
            articleParts:(NSArray *)parts
{
    self = [super initWithConnection:aConnection];
    if (self)
    {
        articleParts = parts;
        partIndex = 0;
    }
    return self;
}

- (void)downloadNextArticle
{
    // Only download the entire article if it is the first part.  Subsequent
    // parts are to have only their body downloaded
    articlePartContent = [[ArticlePartContent alloc] initWithHead:(partIndex == 0)];
    articlePart = [articleParts objectAtIndex:partIndex];
    if (partIndex == 0)
        [connection articleWithMessageId:articlePart.messageId];
    else
        [connection bodyWithMessageId:articlePart.messageId];
        
    ++partIndex;
}

- (void)start
{
    [self downloadNextArticle];
}

#pragma mark -
#pragma mark Notifications

- (void)bytesReceived:(NSNotification *)notification
{
    if (connection.responseCode == 220      // ARTICLE
        || connection.responseCode == 222)  // BODY
    {
        [articlePartContent.data appendData:connection.responseData];

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:ArticleBytesReceivedNotification object:self];
    }
}

- (void)commandResponded:(NSNotification *)notification
{
    if (connection.responseCode == 220      // ARTICLE
        || connection.responseCode == 222)  // BODY
    {
        // Truncate the data, removing the terminating '.'
        // TODO Properly escape the data, removing escaped '.'
        articlePartContent.data.length = articlePartContent.data.length - 3;
    
        // BUG If we post this notification here and now, the owner will
        // release us and any references to instance variables beyond this
        // point will cause a BAD_ACCESS
        
        // !!! FIX !!!
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:ArticleDownloadedNotification object:self];
        
        if (partIndex < articleParts.count)
            [self downloadNextArticle];
        else
            [nc postNotificationName:AllArticlesDownloadedNotification
                              object:self];
    }
    else if (connection.responseCode == 430)
    {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:ArticleUnavailableNotification object:self];
    }
}

@end
