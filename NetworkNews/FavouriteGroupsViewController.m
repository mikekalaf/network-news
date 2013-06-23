//
//  FavouriteGroupsViewController.m
//  Network News
//
//  Created by David Schweinsberg on 30/12/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import "FavouriteGroupsViewController.h"
#import "ThreadListViewController.h"
#import "AppDelegate.h"
#import "SearchGroupsViewController.h"
#import "NewsAccount.h"
#import "NewsConnectionPool.h"
#import "NetworkNews.h"

//static NSString *MostRecentGroupName = @"MostRecentGroupName";

@interface FavouriteGroupsViewController ()
{
}

@end

@implementation FavouriteGroupsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    
    // Load the subscribed groups
    _groupNames = [[NSMutableArray alloc] initWithContentsOfURL:[self groupNamesFileURL]];
    if (!_groupNames)
        _groupNames = [[NSMutableArray alloc] initWithCapacity:1];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Reload so that newly added/removed groups appear when returning
    // from "Search for Groups"
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self saveGroupNamesIfNeeded];

    // Remove any saved search results
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:nil forKey:MOST_RECENT_GROUP_SEARCH];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"EditGroups"])
    {
        SearchGroupsViewController *viewController = (SearchGroupsViewController *)[[segue destinationViewController] topViewController];
        [viewController setConnectionPool:_connectionPool];
        [viewController setCheckedGroups:[_groupNames mutableCopy]];
    }
    else if ([[segue identifier] isEqualToString:@"SelectGroup"])
    {
        NSString *name = [_groupNames objectAtIndex:[[[self tableView] indexPathForSelectedRow] row]];
        ThreadListViewController *viewController = [segue destinationViewController];
        [viewController setConnectionPool:_connectionPool];
        [viewController setGroupName:name];
    }
}

#pragma mark - Public Methods

#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [_groupNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    [[cell textLabel] setText:_groupNames[[indexPath row]]];
    return cell;
}

#pragma mark - UITableViewDelegate Methods

-  (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Delete the cache
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *name = [_groupNames objectAtIndex:[indexPath row]];
        NSURL *cacheURL = [[[_connectionPool account] cacheURL] URLByAppendingPathComponent:name];
        [fileManager removeItemAtURL:cacheURL error:NULL];
        
        // Delete the database
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask,
                                                             YES);
        NSString *documentDir = [paths lastObject];
        NSString *serverDir = [documentDir stringByAppendingPathComponent:[[_connectionPool account] hostName]];
        NSString *storeNameWithExt = [name stringByAppendingPathExtension:@"sqlite"];
        NSString *path = [serverDir stringByAppendingPathComponent:storeNameWithExt];
        NSLog(@"Removing path: %@", path);
        [fileManager removeItemAtPath:path error:NULL];

        // Remove from the table view
        [_groupNames removeObjectAtIndex:[indexPath row]];

        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                         withRowAnimation:YES];
    }   
}

-  (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
       toIndexPath:(NSIndexPath *)toIndexPath
{
    NSString *groupName = [_groupNames objectAtIndex:[fromIndexPath row]];
    [_groupNames removeObjectAtIndex:[fromIndexPath row]];
    [_groupNames insertObject:groupName atIndex:[toIndexPath row]];
}

#pragma mark - Actions

- (IBAction)unwindFromSearchGroups:(UIStoryboardSegue *)segue
{
    if ([[segue identifier] isEqualToString:@"Done"])
    {
        SearchGroupsViewController *sourceViewController = [segue sourceViewController];
        _groupNames = [sourceViewController checkedGroups];
    }
}

//- (IBAction)searchButtonPressed:(id)sender
//{
//    // Load the SearchGroupsViewController
//    SearchGroupsViewController *viewController = [[SearchGroupsViewController alloc] initWithNibName:@"SearchGroupsView"
//                                                                                              bundle:nil];
//    [viewController setConnectionPool:_connectionPool];
//    [viewController setCheckedGroups:_groupNames];
//    [[self navigationController] pushViewController:viewController
//                                           animated:YES];
//}

#pragma mark - Private Methods

- (NSURL *)groupNamesFileURL
{
    return [[[_connectionPool account] cacheURL] URLByAppendingPathComponent:@"groups.plist"];
}

- (void)saveGroupNamesIfNeeded
{
    NSURL *groupNamesURL = [self groupNamesFileURL];
    NSArray *existingGroupNames = [[NSArray alloc] initWithContentsOfURL:groupNamesURL];
    if ([existingGroupNames isEqualToArray:_groupNames] == NO)
        [_groupNames writeToURL:groupNamesURL atomically:YES];
}

@end
