//
//  FavouriteGroupsViewController.h
//  Network News
//
//  Created by David Schweinsberg on 30/12/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NewsConnectionPool;

@interface FavouriteGroupsViewController : UITableViewController

@property (nonatomic) NewsConnectionPool *connectionPool;
@property (nonatomic, copy) NSMutableArray *groupNames;

@end
