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

- (void)accountSettingsViewController:
            (AccountSettingsViewController *)controller
                      modifiedAccount:(NewsAccount *)account;
- (void)accountSettingsViewControllerCancelled:
    (AccountSettingsViewController *)controller;
- (BOOL)accountSettingsViewController:
            (AccountSettingsViewController *)controller
                    verifyAccountName:(NSString *)accountName;

@end

@interface AccountSettingsViewController
    : UITableViewController <UITextFieldDelegate, UIActionSheetDelegate,
                             UIAlertViewDelegate>

@property(nonatomic) NewsAccount *account;
@property(nonatomic, weak) id<AccountSettingsDelegate> delegate;

@end
