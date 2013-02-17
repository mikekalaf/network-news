//
//  FavouriteGroupsViewController.h
//  Network News
//
//  Created by David Schweinsberg on 30/12/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FavouriteGroupsViewController : UITableViewController
{
    NSMutableArray *groups;
    BOOL modified;
}

@property(nonatomic, copy) NSArray *groups;

- (void)restoreLevelWithSelectionArray:(NSArray *)aSelectionArray;

@end
