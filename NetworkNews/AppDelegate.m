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
#import "NSArray+NewsAdditions.h"
#import "NetworkNews.h"
#import "NewsAccount.h"
#import "Preferences.h"

@interface AppDelegate () {
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [Preferences registerDefaults];
  _accounts = [self accountsFromArchive];
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

- (void)swipeLeft:(UIGestureRecognizer *)gestureRecognizer {
  NSLog(@"swipeLeft:");
}

- (void)swipeRight:(UIGestureRecognizer *)gestureRecognizer {
  NSLog(@"swipeRight:");
}

- (NSURL *)accountsFileURL {
  NSFileManager *fileMananger = [[NSFileManager alloc] init];
  NSArray *urls = [fileMananger URLsForDirectory:NSDocumentDirectory
                                       inDomains:NSUserDomainMask];
  return
      [urls.lastObject URLByAppendingPathComponent:NetworkNewsAccountsFileName];
}

- (NSMutableArray *)accountsFromArchive {
  NSData *accountsData = [NSData dataWithContentsOfURL:[self accountsFileURL]];
  if (accountsData)
    return [NSKeyedUnarchiver unarchiveObjectWithData:accountsData];
  else
    return [NSMutableArray array];
}

@end
