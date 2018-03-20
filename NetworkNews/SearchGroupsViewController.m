//
//  SearchGroupsViewController.m
//  Network News
//
//  Created by David Schweinsberg on 24/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "SearchGroupsViewController.h"
#import "GroupListSearchOperation.h"
#import "GroupListing.h"
#import "AppDelegate.h"
#import "NetworkNews.h"

@interface SearchGroupsViewController () <UISearchBarDelegate>
{
    UIActivityIndicatorView *activityIndicatorView;
    NSString *searchText;
    NSInteger searchScope;
    NSArray *_foundGroupList;
    NSOperationQueue *_operationQueue;
}

@property(nonatomic, retain) IBOutlet UISearchBar *searchBar;

@end


@implementation SearchGroupsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Restore the search scope button
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    searchScope = [userDefaults integerForKey:MOST_RECENT_GROUP_SEARCH_SCOPE];
    
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchBar.text = searchText;
    self.searchBar.selectedScopeButtonIndex = searchScope;
    [self.searchBar becomeFirstResponder];
    
    // Create an activity indicator
    activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.hidesWhenStopped = YES;
    [self.view addSubview:activityIndicatorView];
    activityIndicatorView.center = self.view.center;

    _operationQueue = [[NSOperationQueue alloc] init];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // Cancel any live task/connection
    [_operationQueue cancelAllOperations];

//    // Save the group list if it has changed
//    if (modified)
//    {
//        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//        NSString *path = [[appDelegate cacheRootDir] stringByAppendingPathComponent:@"groups.plist"];
//        [_checkedGroups writeToFile:path atomically:YES];
//        modified = NO;
//    }
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _foundGroupList ? _foundGroupList.count : 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    GroupListing *listing = _foundGroupList[indexPath.row];
    NSString *groupName = listing.name;
//    long long articleCount = listInfo.high - listInfo.low + 1;
    long long articleCount = [listing count];
    cell.textLabel.text = groupName;
    if (articleCount > 0)
    {
        cell.textLabel.textColor = [UIColor blackColor];
        NSString *articleText = (articleCount > 1) ? @"Articles" : @"Article";
        cell.detailTextLabel.text = [NSString stringWithFormat:
                                     @"%lld %@",
                                     articleCount,
                                     articleText];
    }
    else
    {
        cell.textLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.text = @"Empty";
    }
    
    // Is it selected as a favourite?
    if ([_checkedGroups containsObject:groupName])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Deselect
    [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow
                             animated:NO];
    
    // Add to or remove from favourites, adding or removing a checkmark also
    NSString *groupName = [_foundGroupList[indexPath.row] name];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([_checkedGroups containsObject:groupName])
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [_checkedGroups removeObject:groupName];
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [_checkedGroups addObject:groupName];
    }
}


#pragma mark - Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

#pragma mark - UISearchBarDelegate Methods

- (void)searchBar:(UISearchBar *)aSearchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:_searchBar.selectedScopeButtonIndex
                      forKey:MOST_RECENT_GROUP_SEARCH_SCOPE];

    [_searchBar becomeFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar
{
    NSLog(@"searchBarSearchButtonClicked:");

    // Ensure the search text is at least three characters long
    if (_searchBar.text.length < 3)
        return;
    
    // Remove the focus from the search field, so the keyboard disappears
    [_searchBar resignFirstResponder];

    [activityIndicatorView startAnimating];
    
    // Cache the search request
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:_searchBar.text forKey:MOST_RECENT_GROUP_SEARCH];
    
    // Build the wildmat
    NSString *wildmat = nil;
    switch (_searchBar.selectedScopeButtonIndex)
    {
        case 0:  // Contains
            wildmat = [NSString stringWithFormat:@"*%@*", _searchBar.text];
            break;
        case 1:  // Begins with
            wildmat = [NSString stringWithFormat:@"%@*", _searchBar.text];
            break;
        case 2:  // Ends with
            wildmat = [NSString stringWithFormat:@"*%@", _searchBar.text];
            break;
    }

    GroupListSearchOperation *operation = [[GroupListSearchOperation alloc] initWithConnectionPool:_connectionPool
                                                                                           wildmat:wildmat];
    operation.completionBlock = ^{
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"count"
                                                                       ascending:NO];
        _foundGroupList = [operation.groups sortedArrayUsingDescriptors:@[sortDescriptor]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [activityIndicatorView stopAnimating];
            [self.tableView reloadData];
        });
    };
    [_operationQueue addOperation:operation];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)aSearchBar
{
    // Cancel any live task/connection
    [_operationQueue cancelAllOperations];
    //[activityIndicatorView stopAnimating];  // This shouldn't be needed

    // Clear the results list
    _foundGroupList = nil;
    [self.tableView reloadData];
}

@end
