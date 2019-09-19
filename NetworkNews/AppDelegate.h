//
//  AppDelegate.h
//  NetworkNews
//
//  Created by David Schweinsberg on 17/02/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ArticleViewController;

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property(nonatomic) UIWindow *window;
@property(nonatomic) UINavigationController *navigationController;
@property(nonatomic) UISplitViewController *splitViewController;
@property(nonatomic) ArticleViewController *articleViewController;
@property(nonatomic) NSMutableArray *accounts;

@property(NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *accountsFileURL;
@property(NS_NONATOMIC_IOSONLY, readonly, copy)
    NSMutableArray *accountsFromArchive;

@end
