//
//  PostArticleTask.h
//  Network News
//
//  Created by David Schweinsberg on 11/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "Task.h"

extern NSString *ArticlePostedNotification;
extern NSString *ArticleNotPostedNotification;

@interface PostArticleTask : Task
{
    NSData *data;
}

- (id)initWithConnection:(NNConnection *)aConnection
                    data:(NSData *)articleData;

@end
