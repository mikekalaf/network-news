//
//  ServersViewController.m
//  Network News
//
//  Created by David Schweinsberg on 26/02/11.
//  Copyright 2011 David Schweinsberg. All rights reserved.
//

#import "ServersViewController.h"
#import "WelcomeViewController.h"
#import "FavouriteGroupsViewController.h"
#import "AccountSettingsViewController.h"
#import "AppDelegate.h"
#import "NetworkNews.h"

@interface ServersViewController ()
{
    NSArray *_accounts;
}

- (void)addButtonPressed:(id)sender;

@end


@implementation ServersViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[self navigationItem] setLeftBarButtonItem:[self editButtonItem]];

    UIBarButtonItem *addButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                  target:self
                                                  action:@selector(addButtonPressed:)];
    [[self navigationItem] setRightBarButtonItem:addButtonItem];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _accounts = [userDefaults objectForKey:ACCOUNTS_NAME_KEY];
    if (!_accounts || [_accounts count] == 0)
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

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


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

    NSDictionary *serverInfo = [_accounts objectAtIndex:[indexPath row]];
    [[cell textLabel] setText:[serverInfo objectForKey:HOSTNAME_KEY]];
    
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
    NSDictionary *accountInfo = [_accounts objectAtIndex:[indexPath row]];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate setUpConnectionWithServerInfo:accountInfo];

    FavouriteGroupsViewController *viewController = [[FavouriteGroupsViewController alloc] initWithNibName:@"FavouriteGroupsView"
                                                                                                    bundle:nil];
    [[self navigationController] pushViewController:viewController animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *accountInfo = [_accounts objectAtIndex:[indexPath row]];

    AccountSettingsViewController *viewController = [[AccountSettingsViewController alloc] initWithNibName:@"AccountSettingsView"
                                                                                                    bundle:nil];
//    [viewController setTitle:title];
//    [[viewController navigationItem] setHidesBackButton:hideBackButton];
    [viewController setAccountInfo:accountInfo];

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
    NSString *title;
    BOOL animated;
    BOOL hideBackButton;
    if (sender)
    {
        title = @"Add News Server";
        animated = YES;
        hideBackButton = NO;
    }
    else
    {
        title = @"Welcome to Network News";
        animated = NO;
        hideBackButton = YES;
    }
    
    // Bring up the welcome view
    WelcomeViewController *viewController = [[WelcomeViewController alloc] initWithNibName:@"WelcomeView"
                                                                                    bundle:nil];
    [viewController setTitle:title];
    [[viewController navigationItem] setHidesBackButton:hideBackButton];
    
    [[self navigationController] pushViewController:viewController animated:animated];
}

@end
