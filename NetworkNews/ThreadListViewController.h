//
//  ThreadListViewController.h
//  Network News
//
//  Created by David Schweinsberg on 20/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupInfoViewController.h"
#import "NewArticleViewController.h"

@interface ThreadListViewController : UITableViewController <
    UISearchBarDelegate,
    UIActionSheetDelegate,
    GroupInfoDelegate,
    NewArticleDelegate
>

@property(nonatomic, copy) NSString *groupName;

- (void)restoreLevelWithSelectionArray:(NSArray *)aSelectionArray;

- (void)returningFromArticleIndex:(NSUInteger)articleIndex;

@end
