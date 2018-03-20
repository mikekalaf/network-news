//
//  WelcomeViewController.m
//  Network News
//
//  Created by David Schweinsberg on 9/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "WelcomeViewController.h"
#import "AccountSettingsViewController.h"
#import "NewsAccount.h"
#import "NetworkNews.h"

#define NEW_ACCOUNT_GIGANEWS        0
//#define NEW_ACCOUNT_POWER_USENET    1
//#define NEW_ACCOUNT_SUPERNEWS       2
//#define NEW_ACCOUNT_USENET_DOT_NET  3
#define NEW_ACCOUNT_OTHER           1

@interface WelcomeViewController () <AccountSettingsDelegate>
{
    NSArray *_templateAccounts;
}

@end

@implementation WelcomeViewController

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    _templateAccounts = @[[NewsAccount accountWithTemplate:AccountTemplateEternalSeptember],
                          [NewsAccount accountWithTemplate:AccountTemplateDefault]];
}

#pragma mark - UITableViewDataSource Methods

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

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LogoCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    if (cell == nil)
//    {
//        cell = [[LogoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
//                                        reuseIdentifier:CellIdentifier];
//    }

    NewsAccount *account = _templateAccounts[indexPath.row];
    if (account.iconName)
    {
        //[[cell imageView] setImage:[UIImage imageNamed:[account iconName]]];
        UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
        imageView.image = [UIImage imageNamed:account.iconName];
    }
    else
    {
        cell.textLabel.text = account.serviceName;
        //[[cell textLabel] setFont:[UIFont boldSystemFontOfSize:24]];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate Methods

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    AccountSettingsViewController *viewController = [[AccountSettingsViewController alloc] initWithNibName:@"AccountSettingsView"
//                                                                                                    bundle:nil];
//    [viewController setAccount:_templateAccounts[indexPath.row]];
//    [viewController setDelegate:self];
//
//    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
//
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
//        [navigationController setModalPresentationStyle:UIModalPresentationFormSheet];
//
//    [self presentViewController:navigationController animated:YES completion:NULL];
//    
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
//        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
//}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    AccountSettingsViewController *viewController = (AccountSettingsViewController *)[segue.destinationViewController topViewController];
    NSIndexPath *selectedRowIndexPath = self.tableView.indexPathForSelectedRow;
    viewController.account = _templateAccounts[selectedRowIndexPath.row];
    viewController.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

#pragma mark - AccountSettingsDelegate Methods

- (void)accountSettingsViewController:(AccountSettingsViewController *)controller
                  modifiedAccount:(NewsAccount *)account
{
    [_accounts addObject:account];

    NSFileManager *fileMananger = [[NSFileManager alloc] init];
    NSArray *urls = [fileMananger URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *accountsURL = [urls.lastObject URLByAppendingPathComponent:NetworkNewsAccountsFileName];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_accounts];
    [data writeToURL:accountsURL atomically:YES];

    [self dismissViewControllerAnimated:YES completion:NULL];
    [self.navigationController popViewControllerAnimated:NO];
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
        if ([controller.account isEqual:account] == NO &&
            [account.serviceName caseInsensitiveCompare:accountName] == NSOrderedSame)
        {
            return NO;
        }
    }
    return YES;
}

@end
