//
//  SearchGroupsViewController.h
//  Network News
//
//  Created by David Schweinsberg on 24/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Task;

@interface SearchGroupsViewController : UITableViewController

@property(nonatomic, retain) NSMutableArray *checkedGroups;

@end
