//
//  WelcomeViewController.m
//  Network News
//
//  Created by David Schweinsberg on 9/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "WelcomeViewController.h"
#import "LogoTableViewCell.h"

#define NEW_ACCOUNT_GIGANEWS        0
//#define NEW_ACCOUNT_POWER_USENET    1
//#define NEW_ACCOUNT_SUPERNEWS       2
//#define NEW_ACCOUNT_USENET_DOT_NET  3
#define NEW_ACCOUNT_OTHER           1

@implementation WelcomeViewController

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

//    self.clearsSelectionOnViewWillAppear = YES;
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[LogoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                         reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row == NEW_ACCOUNT_GIGANEWS)
    {
        cell.imageView.image = [UIImage imageNamed:@"gn.png"];
    }
//    else if (indexPath.row == NEW_ACCOUNT_POWER_USENET)
//    {
//        cell.imageView.image = [UIImage imageNamed:@"pu.png"];
//    }
//    else if (indexPath.row == NEW_ACCOUNT_SUPERNEWS)
//    {
//        cell.imageView.image = [UIImage imageNamed:@"sn.png"];
//    }
//    else if (indexPath.row == NEW_ACCOUNT_USENET_DOT_NET)
//    {
//        cell.imageView.image = [UIImage imageNamed:@"un.png"];
//    }
    else if (indexPath.row == NEW_ACCOUNT_OTHER)
    {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:24];
        cell.textLabel.text = @"Other";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
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
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
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


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *nai = [NSMutableDictionary dictionary];

    if (indexPath.row == NEW_ACCOUNT_GIGANEWS)
    {
        // Giganews
        [nai setObject:@"Giganews" forKey:@"Name"];
        [nai setObject:@"http://www.giganews.com/?c=gn1113881" forKey:@"SupportURL"];
        [nai setObject:@"news.giganews.com" forKey:@"HostName"];
    }
//    else if (indexPath.row == 1)
//    {
//        // Power Usenet
//        [nai setObject:@"Power Usenet" forKey:@"Name"];
//        [nai setObject:@"http://www.powerusenet.com/?a=synchroma" forKey:@"SupportURL"];
//        [nai setObject:@"news.powerusenet.com" forKey:@"HostName"];
//    }
//    else if (indexPath.row == 2)
//    {
//        // Supernews
//        [nai setObject:@"Supernews" forKey:@"Name"];
//        [nai setObject:@"http://www.supernews.com/?a=synchroma" forKey:@"SupportURL"];
//        [nai setObject:@"news.supernews.com" forKey:@"HostName"];
//    }
//    else if (indexPath.row == 3)
//    {
//        // Usenet.net
//        [nai setObject:@"Usenet.net" forKey:@"Name"];
//        [nai setObject:@"http://www.usenet.net/?a=synchroma" forKey:@"SupportURL"];
//        [nai setObject:@"news.usenet.net" forKey:@"HostName"];
//    }
    else if (indexPath.row == NEW_ACCOUNT_OTHER)
    {
        // Other
        [nai setObject:@"Usenet Server" forKey:@"Name"];
    }
    
    NewAccountViewController *viewController = [[NewAccountViewController alloc] initWithNibName:@"NewAccountView"
                                                                                          bundle:nil];
    [viewController setFreshAccountInfo:nai];
    [viewController setDelegate:self];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [navigationController setModalPresentationStyle:UIModalPresentationFormSheet];

    [self presentViewController:navigationController animated:YES completion:NULL];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
#pragma mark NewAccountDelegate Methods

- (void)newAccountViewController:(NewAccountViewController *)controller
                  createdAccount:(NSDictionary *)accountInfo
{
    NSLog(@"New Account: %@", accountInfo);

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *array = [[userDefaults arrayForKey:@"Servers"] mutableCopy];
    if (!array)
        array = [[NSMutableArray alloc] initWithCapacity:1];
    [array addObject:accountInfo];
    [userDefaults setObject:array forKey:@"Servers"];

    [self dismissViewControllerAnimated:YES completion:NULL];
    [[self navigationController] popViewControllerAnimated:NO];
}

- (void)newAccountViewControllerCancelled:(NewAccountViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
