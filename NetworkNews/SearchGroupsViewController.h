//
//  SearchGroupsViewController.h
//  Network News
//
//  Created by David Schweinsberg on 24/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NewsConnectionPool;

@interface SearchGroupsViewController : UITableViewController

@property (nonatomic) NewsConnectionPool *connectionPool;
@property (nonatomic) NSMutableArray *checkedGroups;

@end
