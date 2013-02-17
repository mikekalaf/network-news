//
//  SearchGroupsViewController.h
//  Network News
//
//  Created by David Schweinsberg on 24/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Task;

@interface SearchGroupsViewController : UITableViewController <UISearchBarDelegate>
{
    NSMutableArray *checkedGroups;
    UISearchBar *searchBar;
    UIActivityIndicatorView *activityIndicatorView;
    NSString *searchText;
    NSInteger searchScope;
    NSArray *foundGroupList;
    Task *currentTask;
    BOOL modified;
}

@property(nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property(nonatomic, retain) NSMutableArray *checkedGroups;

- (void)restoreLevel;

@end
