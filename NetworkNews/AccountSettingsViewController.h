//
//  AccountSettingsViewController.h
//  Network News
//
//  Created by David Schweinsberg on 10/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConnectionVerifier.h"

@class AccountSettingsViewController;

@protocol AccountSettingsDelegate

- (void)newAccountViewController:(AccountSettingsViewController *)controller
                  createdAccount:(NSDictionary *)accountInfo;
- (void)newAccountViewControllerCancelled:(AccountSettingsViewController *)controller;

@end

@interface AccountSettingsViewController : UITableViewController
    <ConnectionVerifierDelegate, UITextFieldDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@property(nonatomic) NSDictionary *accountInfo;
@property(nonatomic, weak) id <AccountSettingsDelegate> delegate;

@end
