//
//  SearchGroupsViewController.m
//  Network News
//
//  Created by David Schweinsberg on 24/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "SearchGroupsViewController.h"
#import "GroupListSearchTask.h"
#import "NetworkNewsAppDelegate.h"
#import "NNConnection.h"
#import "NetworkNews.h"

@implementation SearchGroupsViewController

@synthesize searchBar;
@synthesize checkedGroups;

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setTitle:@"Add Groups"];
    
    // Restore the search scope button
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    searchScope = [userDefaults integerForKey:MOST_RECENT_GROUP_SEARCH_SCOPE];
    
    searchBar.text = searchText;
    searchBar.selectedScopeButtonIndex = searchScope;
    
    // Create an activity indicator
    activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.hidesWhenStopped = YES;
    [self.view addSubview:activityIndicatorView];
    activityIndicatorView.center = self.view.center;
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    modified = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // Cancel any live task/connection
    if (currentTask)
    {
        [currentTask cancel];
        currentTask = nil;
    }
    
    // Save the group list if it has changed
    if (modified)
    {
        NetworkNewsAppDelegate *appDelegate = (NetworkNewsAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSString *path = [[appDelegate cacheRootDir] stringByAppendingPathComponent:@"groups.plist"];
        [checkedGroups writeToFile:path atomically:YES];
        modified = NO;
    }
}

/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark -
#pragma mark Public Methods

- (void)restoreLevel
{
    // Restore from the cache
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    searchText = [userDefaults objectForKey:MOST_RECENT_GROUP_SEARCH];
//    searchScope = [userDefaults integerForKey:MOST_RECENT_GROUP_SEARCH_SCOPE];
    if (searchText)
    {
        NetworkNewsAppDelegate *appDelegate = (NetworkNewsAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSString *path = [appDelegate.cacheRootDir stringByAppendingPathComponent:@"search_results.archive"];
        foundGroupList = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    }
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (foundGroupList)
        return foundGroupList.count;
    else
        return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:CellIdentifier];
        cell.textLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
    }
    
    GroupListInfo *listInfo = [foundGroupList objectAtIndex:indexPath.row];
    NSString *groupName = listInfo.name;
//    long long articleCount = listInfo.high - listInfo.low + 1;
    long long articleCount = [listInfo count];
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
    if ([checkedGroups containsObject:groupName])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Deselect
    [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow
                             animated:NO];
    
    // Add to or remove from favourites, adding or removing a checkmark also
    NSString *groupName = [[foundGroupList objectAtIndex:indexPath.row] name];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([checkedGroups containsObject:groupName])
    {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        [checkedGroups removeObject:groupName];
    }
    else
    {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [checkedGroups addObject:groupName];
    }
    modified = YES;
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

- (void)searchBar:(UISearchBar *)aSearchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:searchBar.selectedScopeButtonIndex
                      forKey:MOST_RECENT_GROUP_SEARCH_SCOPE];

    [searchBar becomeFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar
{
    NSLog(@"searchBarSearchButtonClicked:");

    // Ensure the search text is at least three characters long
    if (searchBar.text.length < 3)
        return;
    
    // Remove the focus from the search field, so the keyboard disappears
    [searchBar resignFirstResponder];

    [activityIndicatorView startAnimating];
    
    // Cache the search request
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:searchBar.text forKey:MOST_RECENT_GROUP_SEARCH];
    
    // Build the wildmat
    NSString *wildmat = nil;
    switch (searchBar.selectedScopeButtonIndex)
    {
        case 0:  // Contains
            wildmat = [NSString stringWithFormat:@"*%@*", searchBar.text];
            break;
        case 1:  // Begins with
            wildmat = [NSString stringWithFormat:@"%@*", searchBar.text];
            break;
        case 2:  // Ends with
            wildmat = [NSString stringWithFormat:@"*%@", searchBar.text];
            break;
    }
    
//    refreshButtonItem.enabled = NO;
//    [activityIndicatorView startAnimating];
//    activityTextField.text = @"Downloading all groups...";
//    activityTextField.hidden = NO;
    
    // Issue a LIST ACTIVE <wildmat> command
    NetworkNewsAppDelegate *appDelegate = (NetworkNewsAppDelegate *)[[UIApplication sharedApplication] delegate];
    currentTask = [[GroupListSearchTask alloc] initWithConnection:appDelegate.connection
                                                          wildmat:wildmat];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(listNotification:)
               name:GroupListSearchTaskCompletedNotification
             object:currentTask];
    [nc addObserver:self
           selector:@selector(progressNotification:)
               name:GroupListSearchTaskProgressNotification
             object:currentTask];
    [nc addObserver:self
           selector:@selector(listError:)
               name:TaskErrorNotification
             object:currentTask];

    [currentTask start];
    
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)aSearchBar
{
    // Cancel any live task/connection
    if (currentTask)
    {
        [currentTask cancel];
        currentTask = nil;

        [activityIndicatorView stopAnimating];
    }

    // Clear the results list
    foundGroupList = nil;
    [self.tableView reloadData];
}

//#pragma mark -
//#pragma mark UINavigationBarDelegate Methods
//
//- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item
//{
//    int foo = 0;
//}

#pragma mark -
#pragma mark Notifications

- (void)progressNotification:(NSNotification *)notification
{
//    activityTextField.text = [NSString stringWithFormat:
//                              @"%d groups",
//                              ((GroupListTask *)currentTask).groupsRead];
//    [activityTextField setNeedsDisplay];
}

- (void)listNotification:(NSNotification *)notification
{
    //    activityTextField.text = @"Sorting...";
    
//    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
//                                                                   ascending:YES];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"count"
                                                                   ascending:NO];
    foundGroupList = [((GroupListSearchTask *)currentTask).groupList
                       sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];

    // Cache the results
    NetworkNewsAppDelegate *appDelegate = (NetworkNewsAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *path = [appDelegate.cacheRootDir stringByAppendingPathComponent:@"search_results.archive"];
    [NSKeyedArchiver archiveRootObject:foundGroupList toFile:path];
    
    // We've finished our task
    currentTask = nil;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    
//    [activityIndicatorView stopAnimating];
//    activityTextField.hidden = YES;
//    refreshButtonItem.enabled = YES;
    
    [activityIndicatorView stopAnimating];

    // Update view
    [self.tableView reloadData];
}

- (void)listError:(NSNotification *)notification
{
    AlertViewFailedConnection(currentTask.connection.hostName);
    [self listNotification:notification];
}

@end
