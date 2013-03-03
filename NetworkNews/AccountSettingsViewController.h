//
//  AccountSettingsViewController.h
//  Network News
//
//  Created by David Schweinsberg on 10/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AccountSettingsViewController;
@class NewsAccount;

@protocol AccountSettingsDelegate

- (void)newAccountViewController:(AccountSettingsViewController *)controller
                  createdAccount:(NewsAccount *)account;
- (void)newAccountViewControllerCancelled:(AccountSettingsViewController *)controller;

@end

@interface AccountSettingsViewController : UITableViewController
    <UITextFieldDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@property(nonatomic) NewsAccount *account;
@property(nonatomic, weak) id <AccountSettingsDelegate> delegate;

@end
