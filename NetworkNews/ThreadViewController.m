//
//  ThreadViewController.m
//  Network News
//
//  Created by David Schweinsberg on 21/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ThreadViewController.h"
#import "ThreadListViewController.h"
#import "Article.h"
#import "ExtendedDateFormatter.h"
#import "EmailAddressFormatter.h"
#import "AppDelegate.h"
#import "ThreadTableViewCell.h"
#import "ThreadSectionHeaderView.h"
#import "ArticleViewController.h"

@interface ThreadViewController () <ArticleSource>
{
    NSDateFormatter *dateFormatter;
    NSFormatter *emailAddressFormatter;
    UIImage *unreadIconImage;
    UIImage *readIconImage;
    UIImage *incompleteIconImage;
}

@end

@implementation ThreadViewController

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:[NSString stringWithFormat:@"%d Articles", [_articles count]]];

    // We need to do this just to have the back button show "Thread" rather than the title
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Thread"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
    [[self navigationItem] setBackBarButtonItem:backButtonItem];

    dateFormatter = [[ExtendedDateFormatter alloc] init];
    emailAddressFormatter = [[EmailAddressFormatter alloc] init];
    unreadIconImage = [UIImage imageNamed:@"icon-dot-unread.png"];
    readIconImage = [UIImage imageNamed:@"icon-blank.png"];
    incompleteIconImage = [UIImage imageNamed:@"icon-dot-incomplete.png"];

//    // Set up toolbar
////    UIBarButtonItem *refreshButtonItem =
////    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
////                                                  target:self
////                                                  action:@selector(refreshButtonPressed:)];
//    UIBarButtonItem *flexibleSpaceButtonItem =
//    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
//                                                  target:nil
//                                                  action:nil];
//    UIBarButtonItem *infoButtonItem =
//    [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-toolbar-info.png"]
//                                     style:UIBarButtonItemStylePlain
//                                    target:self
//                                    action:@selector(infoButtonPressed:)];
////    UIBarButtonItem *composeButtonItem =
////    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
////                                                  target:self
////                                                  action:@selector(composeButtonPressed:)];
//    self.toolbarItems = [NSArray arrayWithObjects:
////                         refreshButtonItem,
//                         flexibleSpaceButtonItem,
//                         infoButtonItem,
//                         flexibleSpaceButtonItem,
////                         composeButtonItem,
//                         nil];
////    [refreshButtonItem release];
//    [flexibleSpaceButtonItem release];
//    [infoButtonItem release];
////    [composeButtonItem release];

//    // Scroll the search field just off the top of screen
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//    [self.tableView scrollToRowAtIndexPath:indexPath
//                          atScrollPosition:UITableViewScrollPositionTop
//                                  animated:NO];
    
//    // Sort the articles in the thread in ascending date order
//    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date"
//                                                                   ascending:YES];
//    articles = [thread.articles sortedArrayUsingDescriptors:
//                [NSArray arrayWithObject:sortDescriptor]];
//    [articles retain];
//    
//    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // TODO: Only do this if there is no saved position
//    [[self tableView] scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
//                            atScrollPosition:UITableViewScrollPositionTop
//                                    animated:NO];
    
//    NSLog(@"viewWillAppear, height: %f", self.view.frame.size.height);
}

//- (void)viewDidAppear:(BOOL)animated
//{
//    [super viewDidAppear:animated];
//}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // So the read status is up-to-date on returning
    UIViewController *currentViewController = self.navigationController.topViewController;
    if ([currentViewController isKindOfClass:[ThreadListViewController class]])
    {
        ThreadListViewController *threadListViewController = (ThreadListViewController *)currentViewController;
        [threadListViewController returningFromThreadView];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark Public Methods

- (void)returningFromArticleIndex:(NSUInteger)fromArticleIndex
{
    NSIndexPath *selectedIndexPath = [[self tableView] indexPathForSelectedRow];
    [[self tableView] deselectRowAtIndexPath:selectedIndexPath animated:NO];

    // Update any read/unread info display
    NSArray *indexPaths = [[self tableView] indexPathsForVisibleRows];
    [[self tableView] reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:NO];
    
    // Something a bit weird is going on here.  If I use UITableViewScrollPositionNone,
    // then no scrolling happens at all, so as a workaround I'm deciding myself
    // if it should be top, bottom, or none.
    UITableViewScrollPosition scrollPosition = UITableViewScrollPositionNone;
    if ([indexPaths count] > 0)
    {
        if (fromArticleIndex < [[indexPaths objectAtIndex:0] row])
            scrollPosition = UITableViewScrollPositionTop;
        else if (fromArticleIndex > [[indexPaths objectAtIndex:[indexPaths count] - 1] row])
            scrollPosition = UITableViewScrollPositionBottom;
    }
    else
        scrollPosition = UITableViewScrollPositionMiddle;

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:fromArticleIndex
                                                inSection:0];
    [[self tableView] selectRowAtIndexPath:indexPath
                                  animated:NO
                            scrollPosition:scrollPosition];
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_articles count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _threadTitle;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    ThreadTableViewCell *cell = (ThreadTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[ThreadTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                           reuseIdentifier:CellIdentifier];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    Article *article = [_articles objectAtIndex:indexPath.row];
    cell.textLabel.text = [emailAddressFormatter stringForObjectValue:article.from];
    cell.detailTextLabel.text = article.subject;
    cell.dateLabel.text = [dateFormatter stringFromDate:article.date];
    
    if ([article hasAllParts] == NO)
        [[cell imageView] setImage:incompleteIconImage];
    else if ([[article read] boolValue] == NO)
        [[cell imageView] setImage:unreadIconImage];
    else
        [[cell imageView] setImage:readIconImage];

    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


#pragma mark -
#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        ArticleViewController *viewController = [[ArticleViewController alloc] initWithNibName:@"ArticleView"
                                                                                        bundle:nil];
        viewController.articleSource = self;
        viewController.articleIndex = indexPath.row;
        viewController.groupName = _groupName;

        [self.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
//        ArticleViewController *viewController = appDelegate.articleViewController;
//        
//        viewController.articleSource = self;
//        viewController.articleIndex = indexPath.row;
//        viewController.groupName = groupName;
//        
//        [viewController updateArticle];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    ThreadSectionHeaderView *view = [[ThreadSectionHeaderView alloc] initWithFrame:CGRectZero];
    [[view textLabel] setText:_threadTitle];
    [[view dateLabel] setText:[dateFormatter stringFromDate:_threadDate]];
    return view;
}

#pragma mark -
#pragma mark ArticleSource Methods

- (NSUInteger)articleCount
{
    return [_articles count];
}

- (Article *)articleAtIndex:(NSUInteger)index
{
    return [_articles objectAtIndex:index];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

@end

