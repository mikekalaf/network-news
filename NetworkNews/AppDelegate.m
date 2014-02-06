//
//  AppDelegate.m
//  NetworkNews
//
//  Created by David Schweinsberg on 17/02/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "AppDelegate.h"
#import "AccountsViewController.h"
#import "ArticleViewController.h"
#import "NewsAccount.h"
#import "NSArray+NewsAdditions.h"
#import "NetworkNews.h"
#import "Preferences.h"

@interface AppDelegate ()
{
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Preferences registerDefaults];

    _accounts = [self accountsFromArchive];

//    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
//    {
//        UIViewController *viewController = [[AccountsViewController alloc] initWithNibName:@"AccountsView" bundle:nil];
//        [self setNavigationController:[[UINavigationController alloc] initWithRootViewController:viewController]];
//
//        [[self navigationController] setToolbarHidden:NO];
//        
//        [[self window] setRootViewController:[self navigationController]];
//    }
//    else
//    {
//        UIViewController *masterViewController = [[AccountsViewController alloc] initWithNibName:@"AccountsView" bundle:nil];
//        UINavigationController *masterNavigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
//
//        [masterNavigationController setToolbarHidden:NO];
//
//        _articleViewController = [[ArticleViewController alloc] initWithNibName:@"ArticleView_iPad" bundle:nil];
////        UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:_articleViewController];
//
//        self.splitViewController = [[UISplitViewController alloc] init];
//        self.splitViewController.delegate = _articleViewController;
////        self.splitViewController.viewControllers = @[masterNavigationController, detailNavigationController];
//        [[self splitViewController] setViewControllers:@[masterNavigationController, _articleViewController]];
//
////        // TESTING Try putting our own gesture recogniser in
////        UISwipeGestureRecognizer *gestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
////        [gestureRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
////        [[[self splitViewController] view] addGestureRecognizer:gestureRecognizer];
////
////        gestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
////        [gestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
////        [[[self splitViewController] view] addGestureRecognizer:gestureRecognizer];
//
//        [[self window] setRootViewController:[self splitViewController]];
//    }
//
//    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)swipeLeft:(UIGestureRecognizer *)gestureRecognizer
{
    NSLog(@"swipeLeft:");
}

- (void)swipeRight:(UIGestureRecognizer *)gestureRecognizer
{
    NSLog(@"swipeRight:");
}

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

@end
