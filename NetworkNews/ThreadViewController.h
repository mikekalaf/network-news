//
//  ThreadViewController.h
//  Network News
//
//  Created by David Schweinsberg on 21/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NewsConnectionPool;

@interface ThreadViewController : UITableViewController

@property (nonatomic) NewsConnectionPool *connectionPool;
@property (nonatomic) NSArray *articles;
@property (nonatomic) NSString *threadTitle;
@property (nonatomic) NSDate *threadDate;
@property (nonatomic) NSString *groupName;

- (void)returningFromArticleIndex:(NSUInteger)fromArticleIndex;

@end
