//
//  GroupInfoViewController.h
//  Network News
//
//  Created by David Schweinsberg on 4/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GroupInfoViewController;

@protocol GroupInfoDelegate

- (void)closedGroupInfoController:(GroupInfoViewController *)controller;

@end

@interface GroupInfoViewController : UIViewController
{
    IBOutlet UILabel *groupNameLabel;
    id <GroupInfoDelegate> delegate;
}

@property(nonatomic, retain) id <GroupInfoDelegate> delegate;

@end
