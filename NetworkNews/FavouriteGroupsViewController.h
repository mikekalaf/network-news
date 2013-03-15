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
    BOOL modified;
}

@property(nonatomic, copy) NSMutableArray *groupNames;

- (void)restoreLevelWithSelectionArray:(NSArray *)aSelectionArray;

@end
