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
#import "NNServer.h"
#import "NetworkNews.h"

//static NSString *MostRecentGroupName = @"MostRecentGroupName";

@implementation FavouriteGroupsViewController

@synthesize groups;

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
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *path = [[appDelegate cacheRootDir] stringByAppendingPathComponent:@"groups.plist"];
    groups = [[NSMutableArray alloc] initWithContentsOfFile:path];
    if (!groups)
        groups = [[NSMutableArray alloc] initWithCapacity:1];
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
    
    modified = NO;

    // Remove any saved search results
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:nil forKey:MOST_RECENT_GROUP_SEARCH];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    // Save the group list if it has changed
    if (modified)
    {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSString *path = [[appDelegate cacheRootDir] stringByAppendingPathComponent:@"groups.plist"];
        [groups writeToFile:path atomically:YES];
        modified = NO;
    }
}

/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
}

#pragma mark -
#pragma mark Public Methods

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

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [groups count];
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

    NSString *name = [groups objectAtIndex:[indexPath row]];
    [[cell textLabel] setText:name];

    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate Methods

-       (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *name = [groups objectAtIndex:[indexPath row]];

    ThreadListViewController *viewController = [[ThreadListViewController alloc] initWithNibName:@"ThreadListView"
                                                                                          bundle:nil];
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
        NSString *name = [groups objectAtIndex:[indexPath row]];
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSString *path = [[appDelegate cacheRootDir] stringByAppendingPathComponent:name];
        [fileManager removeItemAtPath:path error:NULL];
        
        // Delete the database
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask,
                                                             YES);
        NSString *documentDir = [paths lastObject];
        NSString *serverDir = [documentDir stringByAppendingPathComponent:[[appDelegate server] hostName]];
        NSString *storeNameWithExt = [name stringByAppendingPathExtension:@"db"];
        path = [serverDir stringByAppendingPathComponent:storeNameWithExt];
        NSLog(@"Removing path: %@", path);
        [fileManager removeItemAtPath:path error:NULL];

        // Remove from the table view
        [groups removeObjectAtIndex:[indexPath row]];

        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                         withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
    
    modified = YES;
}

- (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
      toIndexPath:(NSIndexPath *)toIndexPath
{
    NSString *groupName = [groups objectAtIndex:[fromIndexPath row]];
    [groups removeObjectAtIndex:[fromIndexPath row]];
    [groups insertObject:groupName atIndex:[toIndexPath row]];
    modified = YES;
}

#pragma mark -
#pragma mark Actions

- (IBAction)searchButtonPressed:(id)sender
{
	// Save this level's selection to our AppDelegate
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate.savedLocation addObject:[NSNumber numberWithInteger:-2]];

    // Load the SearchGroupsViewController
    SearchGroupsViewController *viewController = [[SearchGroupsViewController alloc] initWithNibName:@"SearchGroupsView"
                                                                                              bundle:nil];
    [viewController setCheckedGroups:groups];
    [[self navigationController] pushViewController:viewController
                                           animated:YES];
}

@end
