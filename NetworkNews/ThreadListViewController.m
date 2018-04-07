//
//  ThreadListViewController.m
//  Network News
//
//  Created by David Schweinsberg on 20/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ThreadListViewController.h"
#import "ThreadViewController.h"
#import "GroupStore.h"
#import "Article.h"
#import "ArticlePart.h"
#import "Thread.h"
#import "ArticleOverviewsOperation.h"
#import "ExtendedDateFormatter.h"
#import "EmailAddressFormatter.h"
#import "NSString+NewsAdditions.h"
#import "ThreadListTableViewCell.h"
#import "ThreadIterator.h"
#import "NetworkNews.h"
#import "NewsConnectionPool.h"
#import "NewsAccount.h"
#import "GroupInfoViewController.h"
#import "NewArticleViewController.h"
#import "UIColor+NewsAdditions.h"
#import "NNNewsrc.h"

#define DISPLAY_ALL_THREADS     0
#define DISPLAY_FILE_THREADS    1
#define DISPLAY_MESSAGE_THREADS 2

#define THREAD_DISPLAY_KEY      @"ThreadDisplay"


@interface ThreadListViewController () <
    UISearchBarDelegate,
    GroupInfoDelegate,
    NewArticleDelegate
>
{
    NSFetchedResultsController *searchFetchedResultsController;
    UILabel *_statusLabel;
    NSArray *threads;
    NSArray *fileThreads;
    NSArray *messageThreads;
    ThreadIterator *threadIterator;
    GroupStore *_store;
    BOOL silentlyFailConnection;
    NSString *searchText;
    NSUInteger searchScope;
    NSUInteger threadTypeDisplay;

    NSDateFormatter *dateFormatter;
    NSFormatter *emailAddressFormatter;
    UIImage *incompleteIconImage;
    UIImage *unreadIconImage;
    UIImage *readIconImage;
    NSArray *fileExtensions;
    NSOperationQueue *_operationQueue;
}

@property(nonatomic) IBOutlet UIBarButtonItem *statusBarButtonItem;
@property(NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *activeThreads;

- (NSArray *)threadsWithArticles:(NSArray *)articles;
- (void)groupFileSets:(NSMutableDictionary *)threadDict;
- (void)toolbarEnabled:(BOOL)enabled;

@end

@implementation ThreadListViewController

- (void)setGroupName:(NSString *)aGroupName
{
    _groupName = [aGroupName copy];
    _store = [[GroupStore alloc] initWithStoreName:_groupName
                                       inDirectory:_connectionPool.account.serviceName];
    self.title = [_groupName shortGroupName];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Pull to refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(refresh:)
             forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
//    self.navigationItem.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];

    dateFormatter = [[ExtendedDateFormatter alloc] init];
    emailAddressFormatter = [[EmailAddressFormatter alloc] init];
    unreadIconImage = [UIImage imageNamed:@"unread-dot-blue"];
    readIconImage = [UIImage imageNamed:@"icon-blank.png"];
    incompleteIconImage = [UIImage imageNamed:@"icon-dot-incomplete.png"];

    fileExtensions = @[@".jpg",
                       @".png",
                       @".gif",
                       @".mp3",
                       @".mp2",
                       @".mov",
                       @".wav",
                       @".aif",
                       @".zip",
                       @".rar"];

    // Put status label into toolbar button item
    _statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _statusLabel.font = [UIFont systemFontOfSize:11.0];
    [_statusLabel setOpaque:NO];
    _statusLabel.backgroundColor = [UIColor clearColor];
    _statusLabel.textColor = [UIColor toolbarTextColor];
    self.statusBarButtonItem.customView = _statusLabel;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = [userDefaults dictionaryForKey:_groupName];
    threadTypeDisplay = [dict[THREAD_DISPLAY_KEY] integerValue];

    _operationQueue = [[NSOperationQueue alloc] init];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(contextDidSave:)
               name:NSManagedObjectContextDidSaveNotification
             object:nil];

    [self updateThreads];

    // Download the latest articles (this will also do a fetch request)
    silentlyFailConnection = YES;
    [self downloadArticlesWithMode:ArticleOverviewsLatest];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Deselect the selected row (if any)
    UITableView *activeTableView;
//    if (self.searchDisplayController.active)
//        activeTableView = self.searchDisplayController.searchResultsTableView;
//    else
    activeTableView = self.tableView;
    
    NSIndexPath *selectedIndexPath = activeTableView.indexPathForSelectedRow;
    if (selectedIndexPath)
    {
        [activeTableView deselectRowAtIndexPath:selectedIndexPath animated:animated];
        [activeTableView reloadRowsAtIndexPaths:@[selectedIndexPath]
                               withRowAnimation:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    [_operationQueue cancelAllOperations];
}

- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

#pragma mark - Public Methods

- (void)returningFromArticleIndex:(NSUInteger)articleIndex
{
    UITableView *activeTableView;
//    if (self.searchDisplayController.active)
//        activeTableView = self.searchDisplayController.searchResultsTableView;
//    else
    activeTableView = self.tableView;
    
    NSIndexPath *selectedIndexPath = activeTableView.indexPathForSelectedRow;
    [activeTableView deselectRowAtIndexPath:selectedIndexPath animated:NO];

    // Update any read/unread info display
    NSArray *indexPaths = activeTableView.indexPathsForVisibleRows;
    [activeTableView reloadRowsAtIndexPaths:indexPaths
                           withRowAnimation:NO];
    
    NSUInteger index = [threadIterator threadIndexOfArticleIndex:articleIndex];

    // Something a bit weird is going on here.  If I use UITableViewScrollPositionNone,
    // then no scrolling happens at all, so as a workaround I'm deciding myself
    // if it should be top, bottom, or none.
    UITableViewScrollPosition scrollPosition = UITableViewScrollPositionNone;
    NSArray *paths = activeTableView.indexPathsForVisibleRows;

    if (paths.count > 0)
    {
        if (index < [paths[0] row])
            scrollPosition = UITableViewScrollPositionTop;
        else if (index > [paths[paths.count - 1] row])
            scrollPosition = UITableViewScrollPositionBottom;
    }
    else
        scrollPosition = UITableViewScrollPositionMiddle;

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index
                                                inSection:0];
    [activeTableView selectRowAtIndexPath:indexPath
                                 animated:NO
                           scrollPosition:scrollPosition];
}

- (void)returningFromThreadView
{
    // Update any read/unread info display
    NSArray *indexPaths = self.tableView.indexPathsForVisibleRows;
    [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:NO];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
//    if (aTableView == self.searchDisplayController.searchResultsTableView)
//    {
//        // We're showing search results
//        id <NSFetchedResultsSectionInfo> sectionInfo =
//        searchFetchedResultsController.sections[section];
//        return sectionInfo.numberOfObjects;
//    }
//    else
    {
        // If we're displaying no articles, hide the "Load more" cell also
        NSUInteger count = [self activeThreads].count;
        return count ? count + 1 : 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If this row is beyond the end of the list, show a "load more" cell
    if (indexPath.row >= [self activeThreads].count)
        return [aTableView dequeueReusableCellWithIdentifier:@"LoadMoreCell"];

    Thread *thread;

//    if (aTableView == self.searchDisplayController.searchResultsTableView)
//    {
//        // We're showing search results
//        Article *article = [searchFetchedResultsController objectAtIndexPath:indexPath];
//        thread = [[Thread alloc] initWithArticle:article];
//    }
//    else
    thread = [self activeThreads][indexPath.row];

    ThreadListTableViewCell *cell;
    NSUInteger count = thread.articles.count;
    if (count > 1)
        cell = [aTableView dequeueReusableCellWithIdentifier:@"ThreadCell"];
    else
        cell = [aTableView dequeueReusableCellWithIdentifier:@"ArticleCell"];

    UILabel *dateLabel = cell.dateLabel;
    UILabel *subjectLabel = cell.previewLabel;
    UILabel *authorLabel = cell.titleLabel;
    UIImageView *imageView = cell.readStatusImage;

    authorLabel.text = [emailAddressFormatter stringForObjectValue:thread.initialAuthor];
    subjectLabel.text = thread.subject;
    
//    if (count > 1)
//    {
//        [[cell threadCountLabel] setText:[NSString stringWithFormat:@"%d", count]];
//        [[cell threadCountLabel] setHidden:NO];
//    }
//    else
//        [[cell threadCountLabel] setHidden:YES];

    dateLabel.text = [dateFormatter stringFromDate:thread.latestDate];

    if (count == 1 && thread.hasAllParts == NO)
    {
        imageView.image = incompleteIconImage;
        imageView.alpha = 1.0;
    }
    else
    {
        NSUInteger readCount = [self articlesReadInThread:thread];
        if (readCount == 0)
        {
            imageView.image = unreadIconImage;
            imageView.alpha = 1.0;
        }
        else if (readCount < thread.articles.count)
        {
            imageView.image = unreadIconImage;
            imageView.alpha = 0.5;
        }
        else
            imageView.image = readIconImage;
    }

    return cell;
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SelectThread"])
    {
        Thread *thread = [self activeThreads][self.tableView.indexPathForSelectedRow.row];
        ThreadViewController *viewController = segue.destinationViewController;
        viewController.connectionPool = _connectionPool;
        viewController.articles = thread.sortedArticles;
        viewController.threadTitle = thread.subject;
        viewController.groupName = _groupName;
        viewController.threadDate = thread.latestDate;
    }
    else if ([segue.identifier isEqualToString:@"SelectArticle"])
    {
        ArticleViewController *viewController = segue.destinationViewController;
        viewController.connectionPool = _connectionPool;
        viewController.articleSource = threadIterator;
        viewController.articleIndex = [threadIterator articleIndexOfThreadIndex:self.tableView.indexPathForSelectedRow.row];
        viewController.groupName = _groupName;
    }
    else if ([segue.identifier isEqualToString:@"NewArticle"])
    {
        UINavigationController *navigationController = segue.destinationViewController;
        NewArticleViewController *viewController = (NewArticleViewController *)navigationController.topViewController;
        viewController.connectionPool = _connectionPool;
        viewController.delegate = self;
        viewController.groupName = _groupName;
    }
}

#pragma mark - UISearchBarDelegate Methods

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:searchBar.selectedScopeButtonIndex
                      forKey:MOST_RECENT_ARTICLE_SEARCH_SCOPE];
    
    [searchBar becomeFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"searchBarSearchButtonClicked:");
    
    //    [searchFetchedResultsController release];

    // Cache the search request
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:searchBar.text forKey:MOST_RECENT_ARTICLE_SEARCH];
    
    NSManagedObjectContext *context = _store.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Article"
                                              inManagedObjectContext:context];
    fetchRequest.entity = entity;
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    fetchRequest.sortDescriptors = sortDescriptors;

    NSString *format = nil;
    switch (searchBar.selectedScopeButtonIndex)
    {
        case 0:
            format = @"subject CONTAINS[cd] %@";
            break;
        case 1:
            format = @"from CONTAINS[cd] %@";
            break;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              format,
                              searchBar.text];
    NSLog(@"Predicate: %@", predicate.predicateFormat);
    
    fetchRequest.predicate = predicate;
    
    searchFetchedResultsController = [[NSFetchedResultsController alloc]
                                      initWithFetchRequest:fetchRequest
                                      managedObjectContext:context
                                      sectionNameKeyPath:nil
                                      cacheName:nil];

    NSError *error;
    BOOL success = [searchFetchedResultsController performFetch:&error];
    if (!success)
    {
        NSLog(@"searchFetchedResultsController fetch error: %@", error.description);
    }

    // Display the results
//    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // Remove the search request
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:MOST_RECENT_ARTICLE_SEARCH];
}

#pragma mark - NewArticleDelegate Methods

- (void)newArticleViewController:(NewArticleViewController *)controller
                         didSend:(BOOL)send
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - GroupInfoDelegate Methods

- (void)closedGroupInfoController:(GroupInfoViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Actions

- (void)refresh:(id)sender
{
    [self downloadArticlesWithMode:ArticleOverviewsLatest];
    //[self toolbarEnabled:NO];
}

- (void)changeThreadTypeDisplay
{
    threadIterator = [[ThreadIterator alloc] initWithThreads:[self activeThreads]];
    [self.tableView reloadData];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dict = [[userDefaults dictionaryForKey:_groupName] mutableCopy];
    if (!dict)
        dict = [[NSMutableDictionary alloc] initWithCapacity:1];
    dict[THREAD_DISPLAY_KEY] = @(threadTypeDisplay);
    [userDefaults setObject:dict forKey:_groupName];
}

- (IBAction)actionButtonPressed:(id)sender
{
    // Show an action sheet with our various action options
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Show All"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                self->threadTypeDisplay = DISPLAY_ALL_THREADS;
                                                [self changeThreadTypeDisplay];
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Show Files"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                self->threadTypeDisplay = DISPLAY_FILE_THREADS;
                                                [self changeThreadTypeDisplay];
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Show Messages"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                self->threadTypeDisplay = DISPLAY_MESSAGE_THREADS;
                                                [self changeThreadTypeDisplay];
                                            }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)infoButtonPressed:(id)sender
{
    GroupInfoViewController *viewController = [[GroupInfoViewController alloc] init];
    viewController.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];

    [self presentViewController:navigationController animated:YES completion:NULL];
}

#pragma mark - Notifications

- (void)contextDidSave:(NSNotification *)notification
{
    // This is called on the thread of the context doing the changes
    NSLog(@"contextDidSave:");

    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"(merging)");
        [self->_store.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
        [self updateThreads];
    });

    //[_managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
}

//- (void)noSuchGroup:(NSNotification *)notification
//{
//    NSString *errorString = [NSString stringWithFormat:
//                             @"Group doesn't exist on the server \"%@\".",
//                             currentTask.connection.hostName];
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cannot Get News"
//                                                        message:errorString
//                                                       delegate:nil
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//    [alertView show];
//    
//    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//    [nc removeObserver:self];
//    
//    // We've finished our task
//    currentTask = nil;
//    
////    progressView.updatedDate = stack.group.lastUpdate;
////    progressView.status = ProgressViewStatusUpdated;
//    [self setStatusUpdatedDate:[_store lastSaveDate]];
//}
//
//- (void)articleOverviewsError:(NSNotification *)notification
//{
//    // Complain, if not failing silently
//    if (!silentlyFailConnection)
//        AlertViewFailedConnection([[currentTask connection] hostName]);
//    else if ([notification userInfo])
//    {
//        NSString *message = [[notification userInfo] objectForKey:@"Message"];
//        if (message)
//            AlertViewFailedConnectionWithMessage([[currentTask connection] hostName],
//                                                 message);
//    }
//
//    // Forward on, so we perform the fetch
//    [self articleOverviewsLoaded:notification];
//}

#pragma mark - Private Methods

- (void)updateThreads
{
    NSLog(@"Fetching articles");

    // Retrieve the articles from core data
    NSManagedObjectContext *context = _store.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Article"
                                              inManagedObjectContext:context];
    fetchRequest.entity = entity;

    NSError *error;
    NSArray *articles = [context executeFetchRequest:fetchRequest
                                               error:&error];

    // Process into threads
    threads = [self threadsWithArticles:articles];

    // Sort into decending date order
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"latestDate"
                                                                   ascending:NO];
    threads = [threads sortedArrayUsingDescriptors:@[sortDescriptor]];

    // Update the thread iterator
    threadIterator = [[ThreadIterator alloc] initWithThreads:[self activeThreads]];

    // Show the results
    [self.tableView reloadData];

    [self setStatusUpdatedDate:_store.lastUpdate];
    silentlyFailConnection = NO;
}

- (NSArray *)activeThreads
{
    if (!threads)
        return nil;

    if (threadTypeDisplay == DISPLAY_ALL_THREADS)
        return threads;
    else if (threadTypeDisplay == DISPLAY_FILE_THREADS)
    {
        if (!fileThreads)
        {
            NSMutableArray *array = [NSMutableArray array];
            for (Thread *thread in threads)
                if (thread.threadType == ThreadTypeFile)
                    [array addObject:thread];
            fileThreads = [array copy];
        }
        return fileThreads;
    }
    else if (threadTypeDisplay == DISPLAY_MESSAGE_THREADS)
    {
        if (!messageThreads)
        {
            NSMutableArray *array = [NSMutableArray array];
            for (Thread *thread in threads)
                if (thread.threadType == ThreadTypeMessage)
                    [array addObject:thread];
            messageThreads = [array copy];
        }
        return messageThreads;
    }
    return nil;
}

- (NSArray *)threadsWithArticles:(NSArray *)articles
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];

    // Find all the articles that are the first in a thread
    for (Article *article in articles)
    {
        if (!article.references)
        {
            NSString *messageId = (article.messageIds)[0];
            Thread *thread = [[Thread alloc] init];
            thread.subject = article.subject;
            thread.initialAuthor = article.from;
            thread.earliestDate = article.date;
            thread.latestDate = article.date;
            [thread.articles addObject:article];

            thread.messageID = messageId;
            dict[messageId] = thread;
            
            // TESTING
            NSString *subject = article.subject;
            if (subject.length >= 3
                && [subject compare:@"re:"
                            options:NSCaseInsensitiveSearch
                              range:NSMakeRange(0, 3)] == 0)
            {
                NSLog(@"FOLLOW UP WITHOUT REFERENCES: %@", article.subject);
            }
        }
    }
    
    // Thread all articles that contain references
    for (Article *article in articles)
    {
        if (article.references)
        {
            NSArray *references = [article.references componentsSeparatedByString:@" "];
            NSString *messageId = references[0];
        
            Thread *thread = dict[messageId];
            if (thread)
            {
                thread.latestDate = [thread.latestDate laterDate:article.date];
                [thread.articles addObject:article];
            }
            else
            {
//                NSLog(@"ARTICLE: %@", [article subject]);
                
                thread = [[Thread alloc] init];
                thread.subject = article.subject;
                thread.initialAuthor = article.from;
                thread.earliestDate = article.date;
                thread.latestDate = article.date;
                [thread.articles addObject:article];
                
                thread.messageID = messageId;
                dict[messageId] = thread;
            }
        }
    }

    [self groupFileSets:dict];
    
    return dict.allValues;
}

- (BOOL)fileNameInSubject:(NSString *)subject
{
    for (NSString *fileExt in fileExtensions)
        if ([subject rangeOfString:fileExt
                           options:NSCaseInsensitiveSearch].location != NSNotFound)
            return YES;

    return NO;
}

- (void)groupFileSets:(NSMutableDictionary *)threadDict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    
    for (Thread *thread in threadDict.allValues)
    {
        if ([self fileNameInSubject:thread.subject])
        {
            NSString *matchString = [thread.subject stringByReplacingOccurrencesOfNumbersWithString:@"~"];
            Thread *groupThread = dict[matchString];
            if (groupThread)
            {
                [groupThread.articles addObjectsFromArray:thread.articles];
                if ([groupThread.latestDate compare:thread.latestDate] == NSOrderedAscending)
                {
                    groupThread.latestDate = thread.latestDate;
                }
                else if ([groupThread.earliestDate compare:thread.latestDate] == NSOrderedDescending)
                {
                    // Get the earliest subject name of this file group
                    groupThread.earliestDate = thread.latestDate;
                    groupThread.subject = thread.subject;
                }
                [threadDict removeObjectForKey:thread.messageID];
            }
            else
            {
                thread.threadType = ThreadTypeFile;
                dict[matchString] = thread;
                NSLog(@"FILE GROUP: %@", matchString);
            }
        }
    }
}

- (void)downloadArticlesWithMode:(ArticleOverviewsMode)mode
{
    [self setStatusMessage:@"Checking for News..."];
    [self toolbarEnabled:NO];

    NSUInteger maxCount = [[NSUserDefaults standardUserDefaults] integerForKey:MAX_ARTICLE_COUNT_KEY];
    if (maxCount == 0)
        maxCount = 1000;

    NSLog(@"Max Article Count: %lu", (unsigned long)maxCount);

    // Issue an OVER/XOVER command
    ArticleOverviewsOperation *operation = [[ArticleOverviewsOperation alloc] initWithConnectionPool:_connectionPool
                                                                                          groupStore:_store
                                                                                                mode:mode
                                                                                     maxArticleCount:maxCount];
    operation.completionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
            [self toolbarEnabled:YES];
        });
    };
    [_operationQueue addOperation:operation];
}

- (void)toolbarEnabled:(BOOL)enabled
{
    // Set the enabled state of all items except UILabels
    for (UIBarButtonItem *item in self.toolbarItems)
        if ([item.customView isKindOfClass:[UILabel class]] == NO)
            item.enabled = enabled;
}

- (void)setStatusUpdatedDate:(NSDate *)date
{
    if (date == nil)
    {
        [_statusLabel setText:nil];
        return;
    }

    NSTimeInterval timeInterval = date.timeIntervalSinceNow;
    NSString *message;
    if (timeInterval < 60)
    {
        message = @"Updated Just Now";
    }
    else if (timeInterval < 600)
    {
        message = [NSString stringWithFormat:
                   @"Updated %d %@ ago",
                   (int)timeInterval / 60,
                   timeInterval < 120 ? @"minute" : @"minutes"];
    }
    else
    {
        NSString *str = [NSDateFormatter localizedStringFromDate:date
                                                       dateStyle:NSDateFormatterNoStyle
                                                       timeStyle:NSDateFormatterShortStyle];
        message = [NSString stringWithFormat:@"Updated %@", str];
    }
    [self setStatusMessage:message];
}

- (void)setStatusMessage:(NSString *)message
{
    _statusLabel.text = message;
    [_statusLabel sizeToFit];
}

- (NSUInteger)articlesReadInThread:(Thread *)thread
{
    NNNewsrc *newsrc = _connectionPool.account.newsrc;
    NSUInteger readCount = 0;
    for (Article *article in thread.articles)
    {
        ArticlePart *part = [article.parts anyObject];
        NSUInteger number = part.articleNumber.integerValue;
        if ([newsrc isReadForGroupName:_groupName articleNumber:number])
            ++readCount;
    }

    //NSLog(@"%d / %d articles read", readCount, [[thread articles] count]);

    return readCount;
}

@end
