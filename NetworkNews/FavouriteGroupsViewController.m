//
//  FavouriteGroupsViewController.m
//  Network News
//
//  Created by David Schweinsberg on 30/12/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import "FavouriteGroupsViewController.h"
#import "AppDelegate.h"
#import "NNNewsrc.h"
#import "NetworkNews.h"
#import "NewsAccount.h"
#import "NewsConnectionPool.h"
#import "SearchGroupsViewController.h"
#import "ThreadListViewController.h"

@interface FavouriteGroupsViewController () {
  NewsAccount *_account;
}

@end

@implementation FavouriteGroupsViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  // Load the selected news account. Ask for a selection if there isn't one
  NewsAccount *selectedAccount = nil;
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSString *selectedServiceName =
      [userDefaults valueForKey:@"SelectedServiceName"];
  if (selectedServiceName) {
    AppDelegate *appDelegate =
        (AppDelegate *)[UIApplication sharedApplication].delegate;
    for (NewsAccount *account in appDelegate.accounts) {
      if ([selectedServiceName isEqualToString:account.serviceName]) {
        selectedAccount = account;
        break;
      }
    }
  }

  BOOL connect = NO;
  if (_account != selectedAccount) {
    _account = selectedAccount;
    connect = YES;
  }

  if (_account) {
    if (connect) {
      self.connectionPool =
          [[NewsConnectionPool alloc] initWithAccount:_account];

      // Load the subscribed groups
      _groupNames =
          [[_connectionPool.account.newsrc subscribedGroupNames] mutableCopy];
    }
  } else
    dispatch_async(dispatch_get_main_queue(), ^{
      [self performSegueWithIdentifier:@"SelectAccount" sender:self];
    });

  // Reload so that newly added/removed groups appear when returning
  // from "Search for Groups"
  [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  [_connectionPool.account.newsrc sync];

  // Remove any saved search results
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:nil forKey:MOST_RECENT_GROUP_SEARCH];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];

  // Release any cached data, images, etc that aren't in use.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"EditGroups"]) {
    SearchGroupsViewController *viewController = (SearchGroupsViewController *)
        [segue.destinationViewController topViewController];
    viewController.connectionPool = _connectionPool;
    viewController.checkedGroups = [_groupNames mutableCopy];
  } else if ([segue.identifier isEqualToString:@"SelectGroup"]) {
    NSString *name = _groupNames[self.tableView.indexPathForSelectedRow.row];
    ThreadListViewController *viewController = segue.destinationViewController;
    viewController.connectionPool = _connectionPool;
    viewController.groupName = name;
  }
}

#pragma mark - Public Methods

#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return _groupNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
  cell.textLabel.text = _groupNames[indexPath.row];
  return cell;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    //        NSString *name = _groupNames[indexPath.row];

    // Delete the cache
    //        NSFileManager *fileManager = [NSFileManager defaultManager];
    //        NSURL *cacheURL = [[[_connectionPool account] cacheURL]
    //        URLByAppendingPathComponent:name]; [fileManager
    //        removeItemAtURL:cacheURL error:NULL];

    // Remove from the table view
    [_groupNames removeObjectAtIndex:indexPath.row];

    // Delete the row from the data source
    [tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:YES];

    [_connectionPool.account.newsrc setSubscribedGroupNames:_groupNames];
    [_connectionPool.account.newsrc sync];
  }
}

- (void)tableView:(UITableView *)tableView
    moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
           toIndexPath:(NSIndexPath *)toIndexPath {
  NSString *groupName = _groupNames[fromIndexPath.row];
  [_groupNames removeObjectAtIndex:fromIndexPath.row];
  [_groupNames insertObject:groupName atIndex:toIndexPath.row];
  [_connectionPool.account.newsrc setSubscribedGroupNames:_groupNames];
  [_connectionPool.account.newsrc sync];
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView
    willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  NSLog(@"tableView:willBeginEditingRowAtIndexPath:");
}

- (void)tableView:(UITableView *)tableView
    didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  NSLog(@"tableView:didEndEditingRowAtIndexPath:");
}

#pragma mark - Actions

- (IBAction)unwindFromSearchGroups:(UIStoryboardSegue *)segue {
  if ([segue.identifier isEqualToString:@"Done"]) {
    SearchGroupsViewController *sourceViewController =
        segue.sourceViewController;
    [_connectionPool.account.newsrc
        setSubscribedGroupNames:sourceViewController.checkedGroups];

    // Get the subscribed groups via the newsrc object so as to restore
    // group ordering
    _groupNames =
        [[_connectionPool.account.newsrc subscribedGroupNames] mutableCopy];

    [_connectionPool.account.newsrc sync];
  }
}

//- (IBAction)searchButtonPressed:(id)sender
//{
//    // Load the SearchGroupsViewController
//    SearchGroupsViewController *viewController = [[SearchGroupsViewController
//    alloc] initWithNibName:@"SearchGroupsView"
//                                                                                              bundle:nil];
//    [viewController setConnectionPool:_connectionPool];
//    [viewController setCheckedGroups:_groupNames];
//    [[self navigationController] pushViewController:viewController
//                                           animated:YES];
//}

#pragma mark - Private Methods

//- (NSURL *)groupNamesFileURL
//{
//    return [[[_connectionPool account] cacheURL]
//    URLByAppendingPathComponent:@"groups.plist"];
//}
//
//- (void)saveGroupNamesIfNeeded
//{
//    NSURL *groupNamesURL = [self groupNamesFileURL];
//    NSArray *existingGroupNames = [[NSArray alloc]
//    initWithContentsOfURL:groupNamesURL]; if ([existingGroupNames
//    isEqualToArray:_groupNames] == NO)
//        [_groupNames writeToURL:groupNamesURL atomically:YES];
//}

@end
