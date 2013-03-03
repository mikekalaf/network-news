//
//  WelcomeViewController.h
//  Network News
//
//  Created by David Schweinsberg on 9/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccountSettingsViewController.h"

@interface WelcomeViewController : UITableViewController <AccountSettingsDelegate>

@property (nonatomic) NSMutableArray *accounts;

@end
