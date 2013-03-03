//
//  AppDelegate.h
//  NetworkNews
//
//  Created by David Schweinsberg on 17/02/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ViewController;
@class NNServer;
@class NNConnection;
@class NewsAccount;
@class CoreDataStack;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

//@property (strong, nonatomic) ViewController *viewController;
@property (strong, nonatomic) UINavigationController *navigationController;

@property(nonatomic, retain, readonly) NNServer *server;
@property(nonatomic, retain, readonly) NNConnection *connection;
@property(nonatomic, retain, readonly) NSString *cacheRootDir;
@property(nonatomic, retain) CoreDataStack *activeCoreDataStack;
@property(nonatomic, readonly, getter=isServerSetUp) BOOL serverSetUp;

- (void)setUpConnectionWithAccount:(NewsAccount *)account;

@end
