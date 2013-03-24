//
//  AccountsViewController.m
//  Network News
//
//  Created by David Schweinsberg on 26/02/11.
//  Copyright 2011 David Schweinsberg. All rights reserved.
//

#import "AccountsViewController.h"
#import "WelcomeViewController.h"
#import "FavouriteGroupsViewController.h"
#import "AccountSettingsViewController.h"
#import "NewsAccount.h"
#import "NewsConnectionPool.h"
#import "AppDelegate.h"
#import "NetworkNews.h"

@interface AccountsViewController () <AccountSettingsDelegate>
{
    NSMutableArray *_accounts;
}


- (void)addButtonPressed:(id)sender;

@end


@implementation AccountsViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Navigation Bar
    [self setTitle:@"Accounts"];

    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];

//    UIBarButtonItem *addButtonItem =
//    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
//                                                  target:self
//                                                  action:@selector(addButtonPressed:)];
//    [[self navigationItem] setRightBarButtonItem:addButtonItem];

//    // Toolbar
//    UIBarButtonItem *flexibleSpaceButtonItem =
//    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
//                                                  target:nil
//                                                  action:nil];
//    UIBarButtonItem *addButtonItem =
//    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
//                                                  target:self
//                                                  action:@selector(addButtonPressed:)];
//    [self setToolbarItems:@[flexibleSpaceButtonItem, addButtonItem]];

    // Load the accounts data, if we have any
    // (New accounts are written to the archive in WelcomeViewController)
    _accounts = [self accountsFromArchive];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

//    // If there are no accounts, we will prompt the user to create one
//    if ([_accounts count] == 0)
//        [self addButtonPressed:nil];
//    else
//        [[self tableView] reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[self tableView] reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [self saveAccountsIfNeeded];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    // Add/remove the add account cell
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_accounts count] inSection:0];
    if (editing)
        [[self tableView] insertRowsAtIndexPaths:@[indexPath]
                                withRowAnimation:UITableViewRowAnimationFade];
    else
        [[self tableView] deleteRowsAtIndexPaths:@[indexPath]
                                withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self isEditing])
        return [_accounts count] + 1;
    else
        return [_accounts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }

    if ([indexPath row] < [_accounts count])
    {
        NewsAccount *account = [_accounts objectAtIndex:[indexPath row]];
        [[cell textLabel] setText:[account serviceName]];
    }
    else
    {
        [[cell textLabel] setText:@"Add Account"];
    }
    
    return cell;
}

-  (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [_accounts removeObjectAtIndex:[indexPath row]];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                         withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
    }   
}

-  (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
       toIndexPath:(NSIndexPath *)toIndexPath
{
    NewsAccount *account = [_accounts objectAtIndex:[fromIndexPath row]];
    [_accounts removeObjectAtIndex:[fromIndexPath row]];
    [_accounts insertObject:account atIndex:[toIndexPath row]];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ([indexPath row] < [_accounts count]);
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] < [_accounts count])
    {
        // Select an existing account
        NewsAccount *account = _accounts[indexPath.row];

        if ([self isEditing] == NO)
        {
            FavouriteGroupsViewController *viewController = [[FavouriteGroupsViewController alloc] initWithNibName:@"FavouriteGroupsView"
                                                                                                            bundle:nil];
            [viewController setConnectionPool:[[NewsConnectionPool alloc] initWithAccount:account]];
            [[self navigationController] pushViewController:viewController animated:YES];
        }
        else
        {
            AccountSettingsViewController *viewController = [[AccountSettingsViewController alloc] initWithNibName:@"AccountSettingsView"
                                                                                                            bundle:nil];
            [viewController setAccount:account];
            [viewController setDelegate:self];

            [[self navigationController] pushViewController:viewController animated:YES];

//            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
//            [self presentViewController:navigationController animated:YES completion:NULL];
        }
    }
    else
    {
        // Add a new account

        // Bring up the welcome view
        WelcomeViewController *viewController = [[WelcomeViewController alloc] initWithNibName:@"WelcomeView"
                                                                                        bundle:nil];
        [viewController setAccounts:_accounts];
        [viewController setTitle:@"Add News Server"];
        [[self navigationController] pushViewController:viewController animated:YES];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] < [_accounts count])
        return UITableViewCellEditingStyleDelete;
    else
        return UITableViewCellEditingStyleInsert;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

#pragma mark - AccountSettingsDelegate Methods

- (void)accountSettingsViewController:(AccountSettingsViewController *)controller
                  modifiedAccount:(NewsAccount *)account
{
    [self saveAccountsIfNeeded];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)accountSettingsViewControllerCancelled:(AccountSettingsViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL)accountSettingsViewController:(AccountSettingsViewController *)controller
                    verifyAccountName:(NSString *)accountName
{
    // Is the account name unique?
    for (NewsAccount *account in _accounts)
    {
        if ([[controller account] isEqual:account] == NO &&
            [[account serviceName] caseInsensitiveCompare:accountName] == NSOrderedSame)
        {
            return NO;
        }
    }
    return YES;
}

#pragma mark - Actions

- (void)addButtonPressed:(id)sender
{
    // Bring up the welcome view
    WelcomeViewController *viewController = [[WelcomeViewController alloc] initWithNibName:@"WelcomeView"
                                                                                    bundle:nil];
    [viewController setAccounts:_accounts];

    BOOL animated;

    if ([_accounts count] > 0)
    {
        [viewController setTitle:@"Add News Server"];
        [[viewController navigationItem] setHidesBackButton:NO];
        animated = YES;
    }
    else
    {
        [viewController setTitle:@"Welcome to Network News"];
        [[viewController navigationItem] setHidesBackButton:YES];
        animated = NO;
    }
    [[self navigationController] pushViewController:viewController animated:animated];

//    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
//    [self presentViewController:navigationController animated:animated completion:NULL];
}

#pragma mark - Private Methods

- (NSURL *)accountsFileURL
{
    NSFileManager *fileMananger = [[NSFileManager alloc] init];
    NSArray *urls = [fileMananger URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    return [[urls lastObject] URLByAppendingPathComponent:NetworkNewsAccountsFileName];
}

- (NSMutableArray *)accountsFromArchive
{
    NSData *accountsData = [NSData dataWithContentsOfURL:[self accountsFileURL]];
    if (accountsData)
        return [NSKeyedUnarchiver unarchiveObjectWithData:accountsData];
    else
        return [NSMutableArray array];
}

- (void)saveAccountsIfNeeded
{
    NSURL *accountsURL = [self accountsFileURL];
    NSData *accountsData = [NSKeyedArchiver archivedDataWithRootObject:_accounts];
    NSData *existingAccountsData = [NSData dataWithContentsOfURL:accountsURL];
    if ([existingAccountsData isEqualToData:accountsData] == NO)
        [accountsData writeToURL:accountsURL atomically:YES];
}

- (BOOL)isUniqueAccountName:(NSString *)accountName excludingAccount:(NewsAccount *)excludedAccount
{
    for (NewsAccount *account in _accounts)
    {
        if ([excludedAccount isEqual:account] == NO &&
            [[account serviceName] caseInsensitiveCompare:accountName] == NSOrderedSame)
        {
            return NO;
        }
    }
    return YES;
}

@end
