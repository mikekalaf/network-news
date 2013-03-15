//
//  AppDelegate.m
//  NetworkNews
//
//  Created by David Schweinsberg on 17/02/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "AppDelegate.h"
#import "AccountsViewController.h"
#import "NewsAccount.h"
#import "NNServerDelegate.h"
#import "NNServer.h"
#import "NNConnection.h"
#import "NewsConnectionPool.h"
#import "NSArray+NewsAdditions.h"
#import "NetworkNews.h"

@interface AppDelegate () <NNServerDelegate>
{
    NSString *_userName;
    NSString *_password;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Override point for customization after application launch.
    UIViewController *viewController = [[AccountsViewController alloc] initWithNibName:@"AccountsView" bundle:nil];
    [self setNavigationController:[[UINavigationController alloc] initWithRootViewController:viewController]];

    [[self navigationController] setToolbarHidden:NO];
    
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
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
#pragma mark -
#pragma mark Public Methods

- (BOOL)isServerSetUp
{
    if (_server.hostName == nil || [_server.hostName isEqualToString:@""])
        return NO;
    else
        return YES;
}

- (void)setUpConnectionWithAccount:(NewsAccount *)account
{
    _userName = [[account userName] copy];
    _password = [[account password] copy];
    NSString *hostName = [account hostName];
    BOOL secure = [account isSecure];
    NSUInteger port = [account port];
    if (port == 0)
        port = 119;

    if (hostName)
    {
        _server = [[NNServer alloc] initWithHostName:hostName port:port];
        [_server setSecure:secure];
        [_server setDelegate:self];

        _connection = [[NNConnection alloc] initWithServer:_server];
    }

    [self configureCacheForHostName:hostName];

    _connectionPool = [[NewsConnectionPool alloc] initWithAccount:account];
}

#pragma mark - Private Methods

- (void)configureCacheForHostName:(NSString *)hostName
{
    // Create the folders we want to work with
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                         NSUserDomainMask,
                                                         YES);

    // We're setting up the cache root directory without the host name, so that
    // caches are only per group, and not per server.  This is so when a cache is
    // deleted, it is deleted for all servers.
    //    cacheRootDir = [paths objectAtIndex:0];

    _cacheRootDir = [[paths lastObject] stringByAppendingPathComponent:hostName];

    NSLog(@"Cache root: %@", _cacheRootDir);

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:_cacheRootDir
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:NULL];
}

#pragma mark - NNServerDelegate Methods

- (NSString *)userNameForServer:(NNServer *)aServer
{
    return _userName;
}

- (NSString *)passwordForServer:(NNServer *)aServer
{
    return _password;
}

- (void)beginNetworkAccessForServer:(NNServer *)aServer
{
    UIApplication *app = [UIApplication sharedApplication];
    [app setNetworkActivityIndicatorVisible:YES];
}

- (void)endNetworkAccessForServer:(NNServer *)aServer
{
    UIApplication *app = [UIApplication sharedApplication];
    [app setNetworkActivityIndicatorVisible:NO];
}

@end
