//
//  AccountsViewController.m
//  Network News
//
//  Created by David Schweinsberg on 26/02/11.
//  Copyright 2011 David Schweinsberg. All rights reserved.
//

#import "AccountsViewController.h"
#import "AccountSettingsViewController.h"
#import "AppDelegate.h"
#import "FavouriteGroupsViewController.h"
#import "NetworkNews.h"
#import "NewsAccount.h"
#import "NewsConnectionPool.h"
#import "WelcomeViewController.h"

@interface AccountsViewController () <AccountSettingsDelegate> {
  NSMutableArray *_accounts;
  NSString *_selectedServiceName;
}

//- (void)addButtonPressed:(id)sender;

@end

@implementation AccountsViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];

  self.navigationItem.leftBarButtonItem = [self editButtonItem];

  // Load the accounts data, if we have any
  // (New accounts are written to the archive in WelcomeViewController)
  AppDelegate *appDelegate =
      (AppDelegate *)[UIApplication sharedApplication].delegate;
  _accounts = appDelegate.accounts;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  _selectedServiceName = [userDefaults valueForKey:@"SelectedServiceName"];

  // If there are no accounts, we will prompt the user to create one
  if (_accounts.count == 0)
    [self performSegueWithIdentifier:@"AddAccount" sender:self];
  else
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.tableView reloadData];
}

//- (void)viewWillDisappear:(BOOL)animated
//{
//    [super viewWillDisappear:animated];
//}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];

  [self saveAccountsIfNeeded];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return _accounts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
  NewsAccount *account = _accounts[indexPath.row];
  cell.textLabel.text = account.serviceName;

  if ([_selectedServiceName isEqualToString:account.serviceName])
    cell.accessoryType = UITableViewCellAccessoryCheckmark;

  return cell;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    [_accounts removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                     withRowAnimation:UITableViewRowAnimationFade];
  }
}

- (void)tableView:(UITableView *)tableView
    moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
           toIndexPath:(NSIndexPath *)toIndexPath {
  NewsAccount *account = _accounts[fromIndexPath.row];
  [_accounts removeObjectAtIndex:fromIndexPath.row];
  [_accounts insertObject:account atIndex:toIndexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView
    canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  return (indexPath.row < _accounts.count);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"SelectAccount"]) {
    //        NewsAccount *account = _accounts[[[[self tableView]
    //        indexPathForSelectedRow] row]]; FavouriteGroupsViewController
    //        *viewController = [segue destinationViewController];
    //        [viewController setConnectionPool:[[NewsConnectionPool alloc]
    //        initWithAccount:account]];
  } else if ([segue.identifier isEqualToString:@"AddAccount"]) {
    WelcomeViewController *viewController = segue.destinationViewController;
    viewController.accounts = _accounts;

    if (_accounts.count == 0) {
      viewController.title = @"Welcome to Network News";
      [viewController.navigationItem setHidesBackButton:YES];
      // animated = NO;
    }
  } else if ([segue.identifier isEqualToString:@"EditAccount"]) {
    // Configuration is done in
    // tableView:accessoryButtonTappedForRowWithIndexPath:
  }
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NewsAccount *account = _accounts[indexPath.row];
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setValue:account.serviceName forKey:@"SelectedServiceName"];
  [userDefaults synchronize];

  [self.presentingViewController dismissViewControllerAnimated:YES
                                                    completion:NULL];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView
    accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  NewsAccount *account = _accounts[indexPath.row];
  AccountSettingsViewController *viewController =
      (AccountSettingsViewController *)((UINavigationController *)
                                            self.presentedViewController)
          .topViewController;
  viewController.account = account;
  viewController.delegate = self;
}

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];

  // Relinquish ownership any cached data, images, etc. that aren't in use.
}

#pragma mark - AccountSettingsDelegate Methods

- (void)accountSettingsViewController:
            (AccountSettingsViewController *)controller
                      modifiedAccount:(NewsAccount *)account {
  [self saveAccountsIfNeeded];
  [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)accountSettingsViewControllerCancelled:
    (AccountSettingsViewController *)controller {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL)accountSettingsViewController:
            (AccountSettingsViewController *)controller
                    verifyAccountName:(NSString *)accountName {
  // Is the account name unique?
  for (NewsAccount *account in _accounts) {
    if ([controller.account isEqual:account] == NO &&
        [account.serviceName caseInsensitiveCompare:accountName] ==
            NSOrderedSame) {
      return NO;
    }
  }
  return YES;
}

#pragma mark - Actions

//- (void)addButtonPressed:(id)sender
//{
//    // Bring up the welcome view
//    WelcomeViewController *viewController = [[WelcomeViewController alloc]
//    initWithNibName:@"WelcomeView"
//                                                                                    bundle:nil];
//    [viewController setAccounts:_accounts];
//
//    BOOL animated;
//
//    if ([_accounts count] > 0)
//    {
//        [viewController setTitle:@"Add News Server"];
//        [[viewController navigationItem] setHidesBackButton:NO];
//        animated = YES;
//    }
//    else
//    {
//        [viewController setTitle:@"Welcome to Network News"];
//        [[viewController navigationItem] setHidesBackButton:YES];
//        animated = NO;
//    }
//    [[self navigationController] pushViewController:viewController
//    animated:animated];
//
////    UINavigationController *navigationController = [[UINavigationController
///alloc] initWithRootViewController:viewController]; /    [self
///presentViewController:navigationController animated:animated
///completion:NULL];
//}

#pragma mark - Private Methods

- (void)saveAccountsIfNeeded {
  AppDelegate *appDelegate =
      (AppDelegate *)[UIApplication sharedApplication].delegate;
  NSURL *accountsURL = [appDelegate accountsFileURL];
  NSData *accountsData = [NSKeyedArchiver archivedDataWithRootObject:_accounts];
  NSData *existingAccountsData = [NSData dataWithContentsOfURL:accountsURL];
  if ([existingAccountsData isEqualToData:accountsData] == NO)
    [accountsData writeToURL:accountsURL atomically:YES];
}

- (BOOL)isUniqueAccountName:(NSString *)accountName
           excludingAccount:(NewsAccount *)excludedAccount {
  for (NewsAccount *account in _accounts) {
    if ([excludedAccount isEqual:account] == NO &&
        [account.serviceName caseInsensitiveCompare:accountName] ==
            NSOrderedSame) {
      return NO;
    }
  }
  return YES;
}

@end
