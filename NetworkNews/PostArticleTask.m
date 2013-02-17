//
//  PostArticleTask.m
//  Network News
//
//  Created by David Schweinsberg on 11/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "PostArticleTask.h"
#import "NNConnection.h"

NSString *ArticlePostedNotification = @"ArticlePostedNotification";
NSString *ArticleNotPostedNotification = @"ArticleNotPostedNotification";

@implementation PostArticleTask

- (id)initWithConnection:(NNConnection *)aConnection
                    data:(NSData *)articleData
{
    self = [super initWithConnection:aConnection];
    if (self)
    {
        data = articleData;
    }
    return self;
}

- (void)start
{
    [connection post];
}

- (void)sendData
{
    [connection writeData:data];
}

#pragma mark -
#pragma mark Notifications

- (void)commandResponded:(NSNotification *)notification
{
    NSUInteger responseCode = connection.responseCode;
    
    if (responseCode == 340)
    {
        // Send article to be posted
        [self scheduleSelector:@selector(sendData)];
    }
    else if (responseCode == 440)
    {
        // Posting not permitted
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:ArticleNotPostedNotification
                          object:self];
    }
    else if (responseCode == 240)
    {
        // Article received OK
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:ArticlePostedNotification
                          object:self];
    }
    else if (responseCode == 441)
    {
        // Posting failed
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:ArticlePostedNotification
                          object:self];
    }
}

@end
