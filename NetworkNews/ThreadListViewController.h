//
//  ThreadListViewController.h
//  Network News
//
//  Created by David Schweinsberg on 20/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThreadListViewController : UITableViewController

@property(nonatomic, copy) NSString *groupName;

- (void)returningFromArticleIndex:(NSUInteger)articleIndex;
- (void)returningFromThreadView;

@end
