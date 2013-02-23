//
//  ThreadListViewController.m
//  Network News
//
//  Created by David Schweinsberg on 20/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ThreadListViewController.h"
#import "ThreadViewController.h"
#import "GroupCoreDataStack.h"
#import "Group.h"
#import "Article.h"
#import "ArticlePart.h"
#import "Thread.h"
#import "DownloadArticleOverviewsTask.h"
#import "ExtendedDateFormatter.h"
#import "EmailAddressFormatter.h"
#import "NSString+NewsAdditions.h"
#import "NNConnection.h"
#import "AppDelegate.h"
#import "ThreadListTableViewCell.h"
#import "ProgressView.h"
#import "ThreadIterator.h"
#import "NetworkNews.h"
#import "NNServer.h"

#define ONE_DAY_IN_SECONDS      86400
#define ONE_WEEK_IN_SECONDS     7 * ONE_DAY_IN_SECONDS
#define TWO_WEEKS_IN_SECONDS    14 * ONE_DAY_IN_SECONDS
#define FOUR_WEEKS_IN_SECONDS   28 * ONE_DAY_IN_SECONDS

#define REFRESH_ACTION_SHEET    0
#define ACTION_ACTION_SHEET     1

#define DISPLAY_ALL_THREADS     0
#define DISPLAY_FILE_THREADS    1
#define DISPLAY_MESSAGE_THREADS 2

#define THREAD_DISPLAY_KEY      @"ThreadDisplay"

@interface NSString (ReplacingNumbers)

- (NSString *)stringByReplacingOccurrencesOfNumbersWithString:(NSString *)replacement;

@end

@implementation NSString (ReplacingNumbers)

- (NSString *)stringByReplacingOccurrencesOfNumbersWithString:(NSString *)replacement
{
    NSMutableString *newString = [self mutableCopy];
    NSRange searchRange = NSMakeRange(0, [self length]);
    while (searchRange.length)
    {
        NSRange range = [self rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]
                                              options:0
                                                range:searchRange];
        if (range.location == NSNotFound)
            break;

        [newString replaceCharactersInRange:range withString:replacement];
        searchRange.location = NSMaxRange(range);
        searchRange.length = [self length] - searchRange.location;
    }
    return newString;
}

@end

@interface ThreadListViewController (Private)

- (NSArray *)activeThreads;

- (NSArray *)threadsWithArticles:(NSArray *)articles;
- (void)groupFileSets:(NSMutableDictionary *)threadDict;
- (void)downloadWithMode:(DownloadArticleOverviewsTaskMode)mode;
- (void)removeArticlesEarlierThanDate:(NSDate *)date;
- (void)toolbarEnabled:(BOOL)enabled;
- (void)buildThreadListToolbar;

@end

@implementation ThreadListViewController

@synthesize tableView;

- (NSString *)groupName
{
    return groupName;
}

- (void)setGroupName:(NSString *)aGroupName
{
    groupName = [aGroupName copy];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    stack = [[GroupCoreDataStack alloc] initWithGroupName:groupName
                                              inDirectory:[[appDelegate server] hostName]];

    [appDelegate setActiveCoreDataStack:stack];
    
    [self setTitle:[groupName shortGroupName]];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    dateFormatter = [[ExtendedDateFormatter alloc] init];
    emailAddressFormatter = [[EmailAddressFormatter alloc] init];
    unreadIconImage = [UIImage imageNamed:@"icon-dot-unread.png"];
    partReadIconImage = [UIImage imageNamed:@"icon-dot-partread.png"];
    readIconImage = [UIImage imageNamed:@"icon-blank.png"];
    incompleteIconImage = [UIImage imageNamed:@"icon-dot-incomplete.png"];

    fileExtensions = [[NSArray alloc] initWithObjects:
                      @".jpg",
                      @".png",
                      @".gif",
                      @".mp3",
                      @".mp2",
                      @".wav",
                      @".aif",
                      @".zip",
                      @".rar",
                      nil];
    
    [self buildThreadListToolbar];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = [userDefaults dictionaryForKey:groupName];
    threadTypeDisplay = [[dict objectForKey:THREAD_DISPLAY_KEY] integerValue];
    
    if (restoreArticleComposer)
    {
        // Compose article
        NewArticleViewController *viewController = [[NewArticleViewController alloc] initWithGroupName:groupName
                                                                                               subject:nil
                                                                                            references:nil
                                                                                              bodyText:nil];
        viewController.delegate = self;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
        [viewController restoreLevel];

        [self presentViewController:navigationController animated:NO completion:NULL];
    }   
    else if (threads == nil)
    {
        // Download the latest articles (this will also do a fetch request)
        silentlyFailConnection = YES;
        [self downloadWithMode:DownloadArticleOverviewsTaskLatest];
        [self toolbarEnabled:NO];
    }

    // Restore a search?
    if (searchText)
    {
        self.searchDisplayController.active = YES;
        self.searchDisplayController.searchBar.text = searchText;
        self.searchDisplayController.searchBar.selectedScopeButtonIndex = searchScope;
        [self searchBarSearchButtonClicked:self.searchDisplayController.searchBar];
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

//- (void)viewDidAppear:(BOOL)animated
//{
//    [super viewDidAppear:animated];
//}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

    // Cancel any live task/connection
    if (currentTask)
    {
        [currentTask cancel];
        currentTask = nil;
    }
}

/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

- (void)dealloc
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.activeCoreDataStack = nil;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark Public Methods

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

#pragma mark -
#pragma mark UITableViewDataSource Methods

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

- (UITableViewCell *)loadMoreCellWithTableView:(UITableView *)aTableView
{
    static NSString *CellIdentifier = @"LoadMoreCell";

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:CellIdentifier];
        [[cell imageView] setImage:readIconImage];
    }
    
    [[cell textLabel] setText:@"Load More Articles"];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] >= [[self activeThreads] count])
        return [self loadMoreCellWithTableView:aTableView];

    static NSString *CellIdentifier = @"Cell";
    
    ThreadListTableViewCell *cell = (ThreadListTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[ThreadListTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                               reuseIdentifier:CellIdentifier];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    
    Thread *thread;

    if (aTableView == [[self searchDisplayController] searchResultsTableView])
    {
        // We're showing search results
        Article *article = [searchFetchedResultsController objectAtIndexPath:indexPath];
        thread = [[Thread alloc] initWithArticle:article];
    }
    else
        thread = [[self activeThreads] objectAtIndex:indexPath.row];
    
    [[cell textLabel] setText:[emailAddressFormatter stringForObjectValue:[thread initialAuthor]]];
    [[cell detailTextLabel] setText:[thread subject]];
    
    NSUInteger count = [[thread articles] count];
    if (count > 1)
    {
        [[cell threadCountLabel] setText:[NSString stringWithFormat:@"%d", count]];
        [[cell threadCountLabel] setHidden:NO];
    }
    else
        [[cell threadCountLabel] setHidden:YES];

    [[cell dateLabel] setText:[dateFormatter stringFromDate:[thread latestDate]]];

    if (count == 1 && [thread hasAllParts] == NO)
    {
        [[cell imageView] setImage:incompleteIconImage];
        [[cell imageView] setAlpha:1.0];
    }
    else
    {
        ReadStatus readStatus = [thread readStatus];
        if (readStatus == ReadStatusUnread)
        {
            [[cell imageView] setImage:unreadIconImage];
            [[cell imageView] setAlpha:1.0];
        }
        else if (readStatus == ReadStatusPartiallyRead)
        {
    //        [[cell imageView] setImage:partReadIconImage];
            [[cell imageView] setImage:unreadIconImage];
            [[cell imageView] setAlpha:0.5];
        }
        else
            [[cell imageView] setImage:readIconImage];
    }
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Save this level's selection to our AppDelegate
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[[appDelegate savedLocation] addObject:[NSNumber numberWithInteger:[indexPath row]]];
    
    UIViewController *viewController;

    if (aTableView == [[self searchDisplayController] searchResultsTableView])
    {
//        ArticleViewController *articleViewController = [[ArticleViewController alloc] initWithNibName:@"ArticleView"
//                                                                                               bundle:nil];
//        articleViewController.articles = [searchFetchedResultsController fetchedObjects];
//        articleViewController.articleIndex = indexPath.row;
//        articleViewController.groupName = groupName;
//        
//        viewController = articleViewController;
    }
    else
    {
        // Was "Load More" selected?
        if ([indexPath row] >= [[self activeThreads] count])
            return;

        Thread *thread = [[self activeThreads] objectAtIndex:[indexPath row]];
        if ([[thread articles] count] > 1)
            viewController = [[ThreadViewController alloc] initWithArticles:[thread sortedArticles]
                                                                threadTitle:[thread subject]
                                                                 threadDate:[thread latestDate]
                                                                  groupName:groupName];
        else
        {

            ArticleViewController *articleViewController = [[ArticleViewController alloc] initWithNibName:@"ArticleView"
                                                                                                   bundle:nil];
            [articleViewController setArticleSource:threadIterator];
            [articleViewController setArticleIndex:[threadIterator articleIndexOfThreadIndex:[indexPath row]]];
            [articleViewController setGroupName:groupName];

            viewController = articleViewController;
        }
    }
    
    [self.navigationController pushViewController:viewController animated:YES];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

#pragma mark -
#pragma mark UISearchBarDelegate Methods

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
    
    NSManagedObjectContext *context = stack.managedObjectContext;
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

#pragma mark -
#pragma mark UIActionSheetDelegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        // NOP
    }
    else if ([actionSheet tag] == REFRESH_ACTION_SHEET)
    {
        DownloadArticleOverviewsTaskMode mode = 0;
        if (buttonIndex == 0)
            mode = DownloadArticleOverviewsTaskLatest;
        else if (buttonIndex == 1)
            mode = DownloadArticleOverviewsTaskMore;
        [self downloadWithMode:mode];
        
        [self toolbarEnabled:NO];
    }
    else if ([actionSheet tag] == ACTION_ACTION_SHEET)
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
        [tableView reloadData];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *dict = [[userDefaults dictionaryForKey:groupName] mutableCopy];
        if (!dict)
            dict = [[NSMutableDictionary alloc] initWithCapacity:1];
        [dict setObject:[NSNumber numberWithInteger:threadTypeDisplay]
                 forKey:THREAD_DISPLAY_KEY];
        [userDefaults setObject:dict forKey:groupName];
    }
}

#pragma mark -
#pragma mark NewArticleDelegate Methods

- (void)newArticleViewController:(NewArticleViewController *)controller
                         didSend:(BOOL)send
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    restoreArticleComposer = NO;

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate.savedLocation removeLastObject];
}

#pragma mark -
#pragma mark GroupInfoDelegate Methods

- (void)closedGroupInfoController:(GroupInfoViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -
#pragma mark Actions

- (void)refreshButtonPressed:(id)sender
{
    // Show an action sheet with our various refresh options
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Load Latest", @"Load More", nil];
    [actionSheet setTag:REFRESH_ACTION_SHEET];
    [actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (void)actionButtonPressed:(id)sender
{
    // Show an action sheet with our various action options
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Show All", @"Show Files", @"Show Messages", nil];
    [actionSheet setTag:ACTION_ACTION_SHEET];
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
	// Save this level's selection to our AppDelegate
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate.savedLocation addObject:[NSNumber numberWithInteger:-2]];
    
    NewArticleViewController *viewController = [[NewArticleViewController alloc] initWithGroupName:groupName
                                                                                           subject:nil
                                                                                        references:nil
                                                                                          bodyText:nil];
    viewController.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];

    [self presentViewController:navigationController animated:YES completion:NULL];
}

#pragma mark -
#pragma mark Notifications

- (void)articleOverviewsLoaded:(NSNotification *)notification
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    
    // We've finished our task
    currentTask = nil;
    
    NSLog(@"Fetching articles");

    // Retrieve the articles from core data
    NSManagedObjectContext *context = stack.managedObjectContext;
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
    
    // Cache the results
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *path = [appDelegate.cacheRootDir stringByAppendingPathComponent:@"threads.archive"];
    [NSKeyedArchiver archiveRootObject:threads toFile:path];
    
    // Show the results
    [self.tableView reloadData];
    
//    // Push the search bar off the top of the view
//    // (This doesn't work properly because an empty table view with a visible
//    // search bar is first visible)
//    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
//                     atScrollPosition:UITableViewScrollPositionTop
//                             animated:NO];
    
    progressView.updatedDate = stack.group.lastUpdate;
    progressView.status = ProgressViewStatusUpdated;
    silentlyFailConnection = NO;
    [self toolbarEnabled:YES];
}

- (void)noSuchGroup:(NSNotification *)notification
{
    NSString *errorString = [NSString stringWithFormat:
                             @"Group doesn't exist on the server \"%@\".",
                             currentTask.connection.hostName];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cannot Get News"
                                                        message:errorString
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    
    // We've finished our task
    currentTask = nil;
    
    progressView.updatedDate = stack.group.lastUpdate;
    progressView.status = ProgressViewStatusUpdated;
}

- (void)articleOverviewsError:(NSNotification *)notification
{
    // Complain, if not failing silently
    if (!silentlyFailConnection)
        AlertViewFailedConnection([[currentTask connection] hostName]);
    else if ([notification userInfo])
    {
        NSString *message = [[notification userInfo] objectForKey:@"Message"];
        if (message)
            AlertViewFailedConnectionWithMessage([[currentTask connection] hostName],
                                                 message);
    }

    // Forward on, so we perform the fetch
    [self articleOverviewsLoaded:notification];
}

#pragma mark -
#pragma mark Private Methods

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

- (void)downloadWithMode:(DownloadArticleOverviewsTaskMode)mode
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    // Remove old articles
    // (Is this really the best place to do this?)
    NSInteger maxAgeInDays = [userDefaults integerForKey:DELETE_AFTER_DAYS_KEY];
    if (maxAgeInDays == 0)
        maxAgeInDays = 7;

//    NSDate *cutoffDate = [NSDate dateWithTimeIntervalSinceNow:-(maxAgeInDays * ONE_DAY_IN_SECONDS)];
//    [self removeArticlesEarlierThanDate:cutoffDate];

    progressView.status = ProgressViewStatusChecking;
    
    NSUInteger maxCount = [userDefaults integerForKey:MAX_ARTICLE_COUNT_KEY];
    if (maxCount == 0)
        maxCount = 1000;
    
    NSLog(@"Max Article Count: %d", maxCount);
    
    // Issue an OVER/XOVER command
    currentTask = [[DownloadArticleOverviewsTask alloc] initWithConnection:appDelegate.connection
                                                      managedObjectContext:stack.managedObjectContext
                                                                     group:stack.group
                                                                      mode:mode
                                                           maxArticleCount:maxCount];
    
    // Notifications we're interested in
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(articleOverviewsLoaded:)
               name:ArticleOverviewsDownloadedNotification
             object:currentTask];
    [nc addObserver:self
           selector:@selector(noSuchGroup:)
               name:NoSuchGroupNotification
             object:currentTask];
    [nc addObserver:self
           selector:@selector(articleOverviewsError:)
               name:TaskErrorNotification
             object:currentTask];
    
    [currentTask start];
}

- (void)removeArticlesEarlierThanDate:(NSDate *)date
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *groupCachePath = [appDelegate.cacheRootDir stringByAppendingPathComponent:groupName];

    // Delete article parts, and articles, from the database
    NSManagedObjectContext *context = stack.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ArticlePart"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];

    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date < %@", date];
    
    NSError *error;
    NSArray *fetchedArticleParts = [context executeFetchRequest:fetchRequest
                                                          error:&error];
    if (fetchedArticleParts)
    {
        long long highestRemovedArticleNumber = 0;

        for (ArticlePart *articlePart in fetchedArticleParts)
        {
            NSLog(@"Removing part: %@ (%@)", articlePart.articleNumber, articlePart.date);
            
            Article *article = articlePart.article;
            [article removePartsObject:articlePart];
            [context deleteObject:articlePart];
            
            long long articleNumber = articlePart.articleNumber.longLongValue;
            if (highestRemovedArticleNumber < articleNumber)
                highestRemovedArticleNumber = articleNumber;
            
            // If this article has no parts left, then remove the article also
            if (article.parts.count == 0)
            {
//                NSLog(@"Removing: %@ (%@) %@", article.subject, article.from);
                [context deleteObject:article];
            }

            // If this is the first part, then delete any cached files
            if (articlePart.partNumber.integerValue == 1)
            {
                NSString *mIDFileName = [articlePart.messageId messageIDFileName];
                NSString *basePath = [groupCachePath stringByAppendingPathComponent:mIDFileName];

                NSString *path = [basePath stringByAppendingPathExtension:@"head.txt"];
                [fileManager removeItemAtPath:path error:NULL];
                
                path = [basePath stringByAppendingPathExtension:@"top.txt"];
                [fileManager removeItemAtPath:path error:NULL];
                
                NSString *ext = article.attachmentFileName.pathExtension;
                if (ext)
                {
                    path = [basePath stringByAppendingPathExtension:ext];
                    [fileManager removeItemAtPath:path error:NULL];
                }

                path = [basePath stringByAppendingPathExtension:@"bottom.txt"];
                [fileManager removeItemAtPath:path error:NULL];
            }
        }

        // Adjust the lowest article number of the group
        stack.group.lowestArticleNumber = [NSNumber numberWithLongLong:highestRemovedArticleNumber + 1];
    }
}

- (void)toolbarEnabled:(BOOL)enabled
{
    for (UIBarButtonItem *item in self.toolbarItems)
        item.enabled = enabled;
}

//- (void)showProgressToolbar
//{
//    // Set up toolbar
//    UIBarButtonItem *flexibleSpaceButtonItem =
//    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
//                                                  target:nil
//                                                  action:nil];
//    
//    progressView = [[ProgressView alloc] init];
//    [progressView.activityIndicatorView startAnimating];
//    progressView.label.text = @"Downloading...";
//    UIBarButtonItem *progressItem = [[UIBarButtonItem alloc] initWithCustomView:progressView];
//    [progressView release];
//    
//    self.toolbarItems = [NSArray arrayWithObjects:
//                         flexibleSpaceButtonItem,
//                         progressItem,
//                         flexibleSpaceButtonItem,
//                         nil];
//    
//    [flexibleSpaceButtonItem release];
//    [progressItem release];
//}

- (void)buildThreadListToolbar
{
    // Set up toolbar
    UIBarButtonItem *refreshButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                  target:self
                                                  action:@selector(refreshButtonPressed:)];
    UIBarButtonItem *actionButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                  target:self
                                                  action:@selector(actionButtonPressed:)];
    UIBarButtonItem *flexibleSpaceButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                  target:nil
                                                  action:nil];
//    UIBarButtonItem *infoButtonItem =
//    [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-toolbar-info.png"]
//                                     style:UIBarButtonItemStylePlain
//                                    target:self
//                                    action:@selector(infoButtonPressed:)];
    progressView = [[ProgressView alloc] init];
    progressView.updatedDate = stack.group.lastUpdate;
    progressView.status = ProgressViewStatusUpdated;
    UIBarButtonItem *progressItem = [[UIBarButtonItem alloc] initWithCustomView:progressView];
    
    UIBarButtonItem *composeButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                  target:self
                                                  action:@selector(composeButtonPressed:)];
    self.toolbarItems = [NSArray arrayWithObjects:
                         refreshButtonItem,
                         actionButtonItem,
                         flexibleSpaceButtonItem,
//                         infoButtonItem,
                         progressItem,
                         flexibleSpaceButtonItem,
                         composeButtonItem,
                         nil];
}

@end

