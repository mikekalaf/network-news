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

    [self setTitle:@"Groups"];
    
    // Add edit and search buttons
    UIBarButtonItem *searchButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                  target:self
                                                  action:@selector(searchButtonPressed:)];
    [[self navigationItem] setRightBarButtonItem:searchButtonItem];

//    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
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

#pragma mark - Public Methods

- (void)restoreLevelWithSelectionArray:(NSArray *)aSelectionArray
{
//    NSLog(@"FavouriteGroupsViewController restoreLevelWithSelectionArray: %@", aSelectionArray);
//    
//	NSInteger index = [[aSelectionArray objectAtIndex:0] integerValue];
//    
//    if (index == -2)
//    {
//        // Search for Groups
//        SearchGroupsViewController *viewController = [[SearchGroupsViewController alloc] init];
//        [self.navigationController pushViewController:viewController
//                                             animated:NO];
//        [viewController restoreLevel];
//        [viewController release];
//    }
//    else
//    {
//        // Group
////        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
////        NSString *groupName = [userDefaults stringForKey:MostRecentGroupName];
//        NetworkNewsAppDelegate *appDelegate = (NetworkNewsAppDelegate *)[[UIApplication sharedApplication] delegate];
//        NSString *groupName = [appDelegate.myGroups objectAtIndex:index];
//        if (groupName)
//        {
//            ThreadListViewController *viewController = [[ThreadListViewController alloc] initWithGroupName:groupName];
//            [self.navigationController pushViewController:viewController animated:NO];
//
//            NSArray *newSelectionArray = [aSelectionArray subarrayWithRange:NSMakeRange(1, aSelectionArray.count - 1)];
//            [viewController restoreLevelWithSelectionArray:newSelectionArray];
//
//            [viewController release];
//        }
//    }
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [_groupNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [[cell textLabel] setLineBreakMode:NSLineBreakByTruncatingMiddle];
    }

    NSString *name = [_groupNames objectAtIndex:[indexPath row]];
    [[cell textLabel] setText:name];

    return cell;
}

#pragma mark - UITableViewDelegate Methods

-       (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *name = [_groupNames objectAtIndex:[indexPath row]];

    ThreadListViewController *viewController = [[ThreadListViewController alloc] initWithNibName:@"ThreadListView"
                                                                                          bundle:nil];
    [viewController setConnectionPool:_connectionPool];
    [viewController setGroupName:name];
    [[self navigationController] pushViewController:viewController animated:YES];
}

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
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
      toIndexPath:(NSIndexPath *)toIndexPath
{
    NSString *groupName = [_groupNames objectAtIndex:[fromIndexPath row]];
    [_groupNames removeObjectAtIndex:[fromIndexPath row]];
    [_groupNames insertObject:groupName atIndex:[toIndexPath row]];
}

#pragma mark - Actions

- (IBAction)searchButtonPressed:(id)sender
{
    // Load the SearchGroupsViewController
    SearchGroupsViewController *viewController = [[SearchGroupsViewController alloc] initWithNibName:@"SearchGroupsView"
                                                                                              bundle:nil];
    [viewController setConnectionPool:_connectionPool];
    [viewController setCheckedGroups:_groupNames];
    [[self navigationController] pushViewController:viewController
                                           animated:YES];
}

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
