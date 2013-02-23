//
//  ThreadListViewController.h
//  Network News
//
//  Created by David Schweinsberg on 20/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupInfoViewController.h"
#import "NewArticleViewController.h"

@class Task;
@class GroupCoreDataStack;
@class NSFetchedResultsController;
@class ProgressView;
@class ThreadIterator;

@interface ThreadListViewController : UIViewController <
    UITableViewDataSource,
    UITableViewDelegate,
    UISearchBarDelegate,
    UIActionSheetDelegate,
    GroupInfoDelegate,
    NewArticleDelegate
>
{
    UITableView *tableView;
    NSFetchedResultsController *searchFetchedResultsController;
    ProgressView *progressView;
    NSString *groupName;
    NSArray *threads;
    NSArray *fileThreads;
    NSArray *messageThreads;
    ThreadIterator *threadIterator;
    GroupCoreDataStack *stack;
    Task *currentTask;
    BOOL silentlyFailConnection;
    BOOL restoreArticleComposer;
    NSString *searchText;
    NSUInteger searchScope;
    NSUInteger threadTypeDisplay;

    NSDateFormatter *dateFormatter;
    NSFormatter *emailAddressFormatter;
    UIImage *incompleteIconImage;
    UIImage *unreadIconImage;
    UIImage *partReadIconImage;
    UIImage *readIconImage;
    NSArray *fileExtensions;
}

@property(nonatomic, retain) IBOutlet UITableView *tableView;
@property(nonatomic, copy) NSString *groupName;

- (void)returningFromArticleIndex:(NSUInteger)articleIndex;

@end
