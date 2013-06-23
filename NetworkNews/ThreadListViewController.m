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
#import "AppDelegate.h"
#import "ThreadListTableViewCell.h"
#import "ThreadIterator.h"
#import "NetworkNews.h"
#import "NewsConnectionPool.h"
#import "NewsAccount.h"
#import "GroupInfoViewController.h"
#import "NewArticleViewController.h"
#import "UIColor+NewsAdditions.h"

#define ONE_DAY_IN_SECONDS      86400
#define ONE_WEEK_IN_SECONDS     7 * ONE_DAY_IN_SECONDS
#define TWO_WEEKS_IN_SECONDS    14 * ONE_DAY_IN_SECONDS
#define FOUR_WEEKS_IN_SECONDS   28 * ONE_DAY_IN_SECONDS

#define DISPLAY_ALL_THREADS     0
#define DISPLAY_FILE_THREADS    1
#define DISPLAY_MESSAGE_THREADS 2

#define THREAD_DISPLAY_KEY      @"ThreadDisplay"


@interface ThreadListViewController () <
    UISearchBarDelegate,
    UIActionSheetDelegate,
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
    UIImage *partReadIconImage;
    UIImage *readIconImage;
    NSArray *fileExtensions;
    NSOperationQueue *_operationQueue;
}

- (NSArray *)activeThreads;

- (NSArray *)threadsWithArticles:(NSArray *)articles;
- (void)groupFileSets:(NSMutableDictionary *)threadDict;
//- (void)downloadWithMode:(DownloadArticleOverviewsTaskMode)mode;
//- (void)removeArticlesEarlierThanDate:(NSDate *)date;
- (void)toolbarEnabled:(BOOL)enabled;
- (void)buildThreadListToolbar;

@end

@implementation ThreadListViewController

- (void)setGroupName:(NSString *)aGroupName
{
    _groupName = [aGroupName copy];
    _store = [[GroupStore alloc] initWithStoreName:_groupName
                                       inDirectory:[[_connectionPool account] hostName]];
    [self setTitle:[_groupName shortGroupName]];
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
    [self setRefreshControl:refreshControl];

    // At the moment we have the default white background, whereas iOS Mail
    // app has a nicer light grey background
//    [refreshControl setBackgroundColor:[UIColor greenColor]];
//    [[self view] setBackgroundColor:[UIColor redColor]];

    dateFormatter = [[ExtendedDateFormatter alloc] init];
    emailAddressFormatter = [[EmailAddressFormatter alloc] init];
    unreadIconImage = [UIImage imageNamed:@"unread-dot-blue"];
    partReadIconImage = [UIImage imageNamed:@"icon-dot-partread.png"];
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

    [self buildThreadListToolbar];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = [userDefaults dictionaryForKey:_groupName];
    threadTypeDisplay = [[dict objectForKey:THREAD_DISPLAY_KEY] integerValue];

    _operationQueue = [[NSOperationQueue alloc] init];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(contextDidSave:)
               name:NSManagedObjectContextDidSaveNotification
             object:nil];

    [self updateThreads];

//    if (threads == nil)
    {
        // Download the latest articles (this will also do a fetch request)
        silentlyFailConnection = YES;
        [self downloadArticlesWithMode:ArticleOverviewsLatest];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Deselect the selected row (if any)
    UITableView *activeTableView;
    if (self.searchDisplayController.active)
        activeTableView = self.searchDisplayController.searchResultsTableView;
    else
        activeTableView = self.tableView;
    
    NSIndexPath *selectedIndexPath = [activeTableView indexPathForSelectedRow];
    if (selectedIndexPath)
    {
        [activeTableView deselectRowAtIndexPath:selectedIndexPath animated:animated];
        [activeTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:selectedIndexPath]
                               withRowAnimation:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

    // Cancel any live task/connection
//    if (currentTask)
//    {
//        [currentTask cancel];
//        currentTask = nil;
//    }
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
    if (self.searchDisplayController.active)
        activeTableView = self.searchDisplayController.searchResultsTableView;
    else
        activeTableView = self.tableView;
    
    NSIndexPath *selectedIndexPath = [activeTableView indexPathForSelectedRow];
    [activeTableView deselectRowAtIndexPath:selectedIndexPath animated:NO];

    // Update any read/unread info display
    NSArray *indexPaths = [activeTableView indexPathsForVisibleRows];
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
        if (index < [[paths objectAtIndex:0] row])
            scrollPosition = UITableViewScrollPositionTop;
        else if (index > [[paths objectAtIndex:paths.count - 1] row])
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
    NSArray *indexPaths = [[self tableView] indexPathsForVisibleRows];
    [[self tableView] reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:NO];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (aTableView == [[self searchDisplayController] searchResultsTableView])
    {
        // We're showing search results
        id <NSFetchedResultsSectionInfo> sectionInfo =
        [[searchFetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    }
    else
    {
        // If we're displaying no articles, hide the "Load more" cell also
        NSUInteger count = [[self activeThreads] count];
        return count ? count + 1 : 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If this row is beyond the end of the list, show a "load more" cell
    if ([indexPath row] >= [[self activeThreads] count])
        return [aTableView dequeueReusableCellWithIdentifier:@"LoadMoreCell"];

    Thread *thread;

    if (aTableView == [[self searchDisplayController] searchResultsTableView])
    {
        // We're showing search results
        Article *article = [searchFetchedResultsController objectAtIndexPath:indexPath];
        thread = [[Thread alloc] initWithArticle:article];
    }
    else
        thread = [[self activeThreads] objectAtIndex:indexPath.row];

    ThreadListTableViewCell *cell;
    NSUInteger count = [[thread articles] count];
    if (count > 1)
        cell = [aTableView dequeueReusableCellWithIdentifier:@"ThreadCell"];
    else
        cell = [aTableView dequeueReusableCellWithIdentifier:@"ArticleCell"];

    UILabel *dateLabel = [cell dateLabel];
    UILabel *subjectLabel = [cell detailTextLabel];
    UILabel *authorLabel = [cell textLabel];
    UIImageView *imageView = [cell imageView];

    [authorLabel setText:[emailAddressFormatter stringForObjectValue:[thread initialAuthor]]];
    [subjectLabel setText:[thread subject]];
    
//    if (count > 1)
//    {
//        [[cell threadCountLabel] setText:[NSString stringWithFormat:@"%d", count]];
//        [[cell threadCountLabel] setHidden:NO];
//    }
//    else
//        [[cell threadCountLabel] setHidden:YES];

    [dateLabel setText:[dateFormatter stringFromDate:[thread latestDate]]];

    if (count == 1 && [thread hasAllParts] == NO)
    {
        [imageView setImage:incompleteIconImage];
        [imageView setAlpha:1.0];
    }
    else
    {
        ReadStatus readStatus = [thread readStatus];
        if (readStatus == ReadStatusUnread)
        {
            [imageView setImage:unreadIconImage];
            [imageView setAlpha:1.0];
        }
        else if (readStatus == ReadStatusPartiallyRead)
        {
    //        [[cell imageView] setImage:partReadIconImage];
            [imageView setImage:unreadIconImage];
            [imageView setAlpha:0.5];
        }
        else
            [imageView setImage:readIconImage];
    }

    return cell;
}

#pragma mark - UITableViewDelegate Methods

//- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (aTableView == [[self searchDisplayController] searchResultsTableView])
//    {
////        ArticleViewController *articleViewController = [[ArticleViewController alloc] initWithNibName:@"ArticleView"
////                                                                                               bundle:nil];
////        articleViewController.articles = [searchFetchedResultsController fetchedObjects];
////        articleViewController.articleIndex = indexPath.row;
////        articleViewController.groupName = _groupName;
////        
////        viewController = articleViewController;
//    }
//    else
//    {
//        // Was "Load More" selected?
//        if ([indexPath row] >= [[self activeThreads] count])
//        {
//            [self downloadArticlesWithMode:ArticleOverviewsMore];
//            return;
//        }
//
//        // Was a thread or an individual article selected?
//        Thread *thread = [[self activeThreads] objectAtIndex:[indexPath row]];
//        if ([[thread articles] count] > 1)
//        {
//            ThreadViewController *viewController = [[ThreadViewController alloc] initWithNibName:@"ThreadView"
//                                                                                          bundle:nil];
//            [viewController setConnectionPool:_connectionPool];
//            [viewController setArticles:[thread sortedArticles]];
//            [viewController setThreadTitle:[thread subject]];
//            [viewController setGroupName:_groupName];
//            [viewController setThreadDate:[thread latestDate]];
//            [self.navigationController pushViewController:viewController animated:YES];
//        }
//        else
//        {
//            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
//            {
//                ArticleViewController *viewController = [[ArticleViewController alloc] initWithNibName:@"ArticleView"
//                                                                                                bundle:nil];
//                [viewController setConnectionPool:_connectionPool];
//                [viewController setArticleSource:threadIterator];
//                [viewController setArticleIndex:[threadIterator articleIndexOfThreadIndex:[indexPath row]]];
//                [viewController setGroupName:_groupName];
//                [self.navigationController pushViewController:viewController animated:YES];
//            }
//            else
//            {
//                // Use the main content view
//                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//                ArticleViewController *viewController = [appDelegate articleViewController];
//                [viewController setConnectionPool:_connectionPool];
//                [viewController setArticleSource:threadIterator];
//                [viewController setArticleIndex:[threadIterator articleIndexOfThreadIndex:[indexPath row]]];
//                [viewController setGroupName:_groupName];
//                [viewController updateArticle];
//            }
//        }
//    }
//}


#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"SelectThread"])
    {
        Thread *thread = [[self activeThreads] objectAtIndex:[[[self tableView] indexPathForSelectedRow] row]];
        ThreadViewController *viewController = [segue destinationViewController];
        [viewController setConnectionPool:_connectionPool];
        [viewController setArticles:[thread sortedArticles]];
        [viewController setThreadTitle:[thread subject]];
        [viewController setGroupName:_groupName];
        [viewController setThreadDate:[thread latestDate]];
    }
    else if ([[segue identifier] isEqualToString:@"SelectArticle"])
    {
        ArticleViewController *viewController = [segue destinationViewController];
        [viewController setConnectionPool:_connectionPool];
        [viewController setArticleSource:threadIterator];
        [viewController setArticleIndex:[threadIterator articleIndexOfThreadIndex:[[[self tableView] indexPathForSelectedRow] row]]];
        [viewController setGroupName:_groupName];
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
    [fetchRequest setEntity:entity];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

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

//    // Cache the results
//
//    // Build an array of all the article coredata URIs, and encode the array
//    NSArray *fetchedObjects = searchFetchedResultsController.fetchedObjects;
//    NSMutableArray *array = [NSMutableArray arrayWithCapacity:fetchedObjects.count];
//    for (Article *article in fetchedObjects)
//        [array addObject:article.objectID.URIRepresentation];
//    
//    NetworkNewsAppDelegate *appDelegate = (NetworkNewsAppDelegate *)[[UIApplication sharedApplication] delegate];
//    NSString *path = [appDelegate.cacheRootDir stringByAppendingPathComponent:@"article_search_results.archive"];
//    [NSKeyedArchiver archiveRootObject:array toFile:path];

    // Display the results
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // Remove the search request
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:MOST_RECENT_ARTICLE_SEARCH];

//    // Delete any cached results
//    NetworkNewsAppDelegate *appDelegate = (NetworkNewsAppDelegate *)[[UIApplication sharedApplication] delegate];
//    NSString *path = [appDelegate.cacheRootDir stringByAppendingPathComponent:@"article_search_results.archive"];
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    [fileManager removeItemAtPath:path error:NULL];
}

#pragma mark - UIActionSheetDelegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        // NOP
    }
    else
    {
        if (buttonIndex == 0)
        {
            threadTypeDisplay = DISPLAY_ALL_THREADS;
        }
        else if (buttonIndex == 1)
        {
            threadTypeDisplay = DISPLAY_FILE_THREADS;
        }
        else if (buttonIndex == 2)
        {
            threadTypeDisplay = DISPLAY_MESSAGE_THREADS;
        }
        threadIterator = [[ThreadIterator alloc] initWithThreads:[self activeThreads]];
        [[self tableView] reloadData];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *dict = [[userDefaults dictionaryForKey:_groupName] mutableCopy];
        if (!dict)
            dict = [[NSMutableDictionary alloc] initWithCapacity:1];
        [dict setObject:[NSNumber numberWithInteger:threadTypeDisplay]
                 forKey:THREAD_DISPLAY_KEY];
        [userDefaults setObject:dict forKey:_groupName];
    }
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

- (void)actionButtonPressed:(id)sender
{
    // Show an action sheet with our various action options
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Show All", @"Show Files", @"Show Messages", nil];
    [actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (void)infoButtonPressed:(id)sender
{
    GroupInfoViewController *viewController = [[GroupInfoViewController alloc] init];
    viewController.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];

    [self presentViewController:navigationController animated:YES completion:NULL];
}

- (void)composeButtonPressed:(id)sender
{
    NewArticleViewController *viewController;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        viewController = [[NewArticleViewController alloc] initWithNibName:@"NewArticleView" bundle:nil];
    else
        viewController = [[NewArticleViewController alloc] initWithNibName:@"NewArticleView" bundle:nil];
    [viewController setConnectionPool:_connectionPool];
    [viewController setDelegate:self];
    [viewController setGroupName:_groupName];

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
        [[_store managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
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
    [fetchRequest setEntity:entity];

    NSError *error;
    NSArray *articles = [context executeFetchRequest:fetchRequest
                                               error:&error];

    // Process into threads
    threads = [self threadsWithArticles:articles];

    // Sort into decending date order
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"latestDate"
                                                                   ascending:NO];
    threads = [threads sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];

    // Update the thread iterator
    threadIterator = [[ThreadIterator alloc] initWithThreads:[self activeThreads]];

//    // Cache the results
//    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    NSString *path = [appDelegate.cacheRootDir stringByAppendingPathComponent:@"threads.archive"];
//    [NSKeyedArchiver archiveRootObject:threads toFile:path];

    // Show the results
    [self.tableView reloadData];

    //    // Push the search bar off the top of the view
    //    // (This doesn't work properly because an empty table view with a visible
    //    // search bar is first visible)
    //    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
    //                     atScrollPosition:UITableViewScrollPositionTop
    //                             animated:NO];

    //    progressView.updatedDate = stack.group.lastUpdate;
    //    progressView.status = ProgressViewStatusUpdated;
    [self setStatusUpdatedDate:[_store lastUpdate]];
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
                if ([thread threadType] == ThreadTypeFile)
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
                if ([thread threadType] == ThreadTypeMessage)
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
        if (![article references])
        {
            NSString *messageId = [article.messageIds objectAtIndex:0];
            Thread *thread = [[Thread alloc] init];
            [thread setSubject:[article subject]];
            [thread setInitialAuthor:[article from]];
            [thread setEarliestDate:[article date]];
            [thread setLatestDate:[article date]];
            [[thread articles] addObject:article];

            [thread setMessageID:messageId];
            [dict setObject:thread forKey:messageId];
            
            // TESTING
            NSString *subject = [article subject];
            if ([subject length] >= 3
                && [subject compare:@"re:"
                            options:NSCaseInsensitiveSearch
                              range:NSMakeRange(0, 3)] == 0)
            {
                NSLog(@"FOLLOW UP WITHOUT REFERENCES: %@", [article subject]);
            }
        }
    }
    
    // Thread all articles that contain references
    for (Article *article in articles)
    {
        if ([article references])
        {
            NSArray *references = [article.references componentsSeparatedByString:@" "];
            NSString *messageId = [references objectAtIndex:0];
        
            Thread *thread = [dict objectForKey:messageId];
            if (thread)
            {
                [thread setLatestDate:[[thread latestDate] laterDate:[article date]]];
                [[thread articles] addObject:article];
            }
            else
            {
//                NSLog(@"ARTICLE: %@", [article subject]);
                
                thread = [[Thread alloc] init];
                thread.subject = article.subject;
                [thread setInitialAuthor:[article from]];
                [thread setEarliestDate:[article date]];
                thread.latestDate = article.date;
                [thread.articles addObject:article];
                
                [thread setMessageID:messageId];
                [dict setObject:thread forKey:messageId];
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
    
    for (Thread *thread in [threadDict allValues])
    {
        if ([self fileNameInSubject:[thread subject]])
        {
            NSString *matchString = [[thread subject] stringByReplacingOccurrencesOfNumbersWithString:@"~"];
            Thread *groupThread = [dict objectForKey:matchString];
            if (groupThread)
            {
                [[groupThread articles] addObjectsFromArray:[thread articles]];
                if ([[groupThread latestDate] compare:[thread latestDate]] == NSOrderedAscending)
                {
                    [groupThread setLatestDate:[thread latestDate]];
                }
                else if ([[groupThread earliestDate] compare:[thread latestDate]] == NSOrderedDescending)
                {
                    // Get the earliest subject name of this file group
                    [groupThread setEarliestDate:[thread latestDate]];
                    [groupThread setSubject:[thread subject]];
                }
                [threadDict removeObjectForKey:[thread messageID]];
            }
            else
            {
                [thread setThreadType:ThreadTypeFile];
                [dict setObject:thread forKey:matchString];
                NSLog(@"FILE GROUP: %@", matchString);
            }
        }
    }
}

- (void)downloadArticlesWithMode:(ArticleOverviewsMode)mode
{
    [self setStatusMessage:@"Checking for News..."];
    [[self refreshControl] beginRefreshing];
    [self toolbarEnabled:NO];

    NSUInteger maxCount = [[NSUserDefaults standardUserDefaults] integerForKey:MAX_ARTICLE_COUNT_KEY];
    if (maxCount == 0)
        maxCount = 1000;

    NSLog(@"Max Article Count: %d", maxCount);

    // Issue an OVER/XOVER command
    ArticleOverviewsOperation *operation = [[ArticleOverviewsOperation alloc] initWithConnectionPool:_connectionPool
                                                                                          groupStore:_store
                                                                                                mode:mode
                                                                                     maxArticleCount:maxCount];
    [operation setCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self refreshControl] endRefreshing];
            [self toolbarEnabled:YES];
        });
    }];
    [_operationQueue addOperation:operation];
}

- (void)toolbarEnabled:(BOOL)enabled
{
    // Set the enabled state of all items except UILabels
    for (UIBarButtonItem *item in [self toolbarItems])
        if ([[item customView] isKindOfClass:[UILabel class]] == NO)
            [item setEnabled:enabled];
}

- (void)buildThreadListToolbar
{
    // Set up toolbar
    UIBarButtonItem *flexibleSpaceButtonItem1 =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                  target:nil
                                                  action:nil];
    UIBarButtonItem *flexibleSpaceButtonItem2 =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                  target:nil
                                                  action:nil];
//    UIBarButtonItem *infoButtonItem =
//    [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-toolbar-info.png"]
//                                     style:UIBarButtonItemStylePlain
//                                    target:self
//                                    action:@selector(infoButtonPressed:)];

    _statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [_statusLabel setFont:[UIFont systemFontOfSize:11.0]];
    [_statusLabel setOpaque:NO];
    [_statusLabel setBackgroundColor:[UIColor clearColor]];
    [_statusLabel setTextColor:[UIColor toolbarTextColor]];
    UIBarButtonItem *statusItem = [[UIBarButtonItem alloc] initWithCustomView:_statusLabel];

    // If we're on an iPad, then the article view controller handles the toolbar commands
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
//        [_statusLabel setShadowColor:[UIColor whiteColor]];
//        [_statusLabel setShadowOffset:CGSizeMake(0, 1)];

        [self setToolbarItems:@[flexibleSpaceButtonItem1, statusItem, flexibleSpaceButtonItem2]];
    }
    else
    {
//        [_statusLabel setShadowColor:[UIColor darkGrayColor]];

        UIBarButtonItem *actionButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                      target:self
                                                      action:@selector(actionButtonPressed:)];
        UIBarButtonItem *composeButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                      target:self
                                                      action:@selector(composeButtonPressed:)];
        [self setToolbarItems:
         @[actionButtonItem,
         flexibleSpaceButtonItem1,
         statusItem,
         flexibleSpaceButtonItem2,
         composeButtonItem]];
    }
}

- (void)setStatusUpdatedDate:(NSDate *)date
{
    if (date == nil)
    {
        [_statusLabel setText:nil];
        return;
    }

//    NSString *str = [NSDateFormatter localizedStringFromDate:date
//                                                   dateStyle:NSDateFormatterShortStyle
//                                                   timeStyle:NSDateFormatterShortStyle];
//    NSArray *components = @[@"Updated "];
//    components = [components arrayByAddingObjectsFromArray:[str componentsSeparatedByString:@" "]];
//    NSArray *fonts = @[[UIFont boldSystemFontOfSize:12.0],
//                       [UIFont systemFontOfSize:12.0]];
//
//    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
//    int index = 0;
//    for (NSString *component in components)
//    {
//        if ([text length] > 0)
//            [text appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
//        [text appendAttributedString:[[NSMutableAttributedString alloc] initWithString:component
//                                                                            attributes:@{NSFontAttributeName: fonts[index]}]];
//        index = (index + 1) % [fonts count];
//    }
//
//    [_statusLabel setAttributedText:text];
//    [_statusLabel sizeToFit];

    NSTimeInterval timeInterval = [date timeIntervalSinceNow];

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

    [_statusLabel setText:message];
    [_statusLabel sizeToFit];
}

- (void)setStatusMessage:(NSString *)message
{
    [_statusLabel setText:message];
//    [_statusLabel setFont:[UIFont systemFontOfSize:12.0]];
    [_statusLabel sizeToFit];
}

@end
