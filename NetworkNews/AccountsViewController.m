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
#import "AppDelegate.h"
#import "NetworkNews.h"

@interface AccountsViewController ()
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

    [self setTitle:@"Accounts"];

    [[self navigationItem] setLeftBarButtonItem:[self editButtonItem]];

    UIBarButtonItem *addButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                  target:self
                                                  action:@selector(addButtonPressed:)];
    [[self navigationItem] setRightBarButtonItem:addButtonItem];

    // Load the accounts data, if we have any
    // (New accounts are written to the archive in WelcomeViewController)
    NSFileManager *fileMananger = [[NSFileManager alloc] init];
    NSArray *urls = [fileMananger URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *accountsURL = [[urls lastObject] URLByAppendingPathComponent:NetworkNewsAccountsFileName];
    NSData *accountsData = [NSData dataWithContentsOfURL:accountsURL];
    if (accountsData)
        _accounts = [NSKeyedUnarchiver unarchiveObjectWithData:accountsData];
    else
        _accounts = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // If there are no accounts, we will prompt the user to create one
    if ([_accounts count] == 0)
        [self addButtonPressed:nil];
    else
        [[self tableView] reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_accounts count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier];
        [cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
    }

    NewsAccount *account = [_accounts objectAtIndex:[indexPath row]];
    [[cell textLabel] setText:[account hostName]];
    
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
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NewsAccount *account = _accounts[indexPath.row];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate setUpConnectionWithAccount:account];

    FavouriteGroupsViewController *viewController = [[FavouriteGroupsViewController alloc] initWithNibName:@"FavouriteGroupsView"
                                                                                                    bundle:nil];
    [[self navigationController] pushViewController:viewController animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NewsAccount *account = _accounts[indexPath.row];

    AccountSettingsViewController *viewController = [[AccountSettingsViewController alloc] initWithNibName:@"AccountSettingsView"
                                                                                                    bundle:nil];
//    [viewController setTitle:title];
//    [[viewController navigationItem] setHidesBackButton:hideBackButton];
    [viewController setAccount:account];

    [[self navigationController] pushViewController:viewController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
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
}

@end
