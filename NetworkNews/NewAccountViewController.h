//
//  NewAccountViewController.h
//  Network News
//
//  Created by David Schweinsberg on 10/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConnectionVerifier.h"

@class NewAccountViewController;

@protocol NewAccountDelegate

- (void)newAccountViewController:(NewAccountViewController *)controller
                  createdAccount:(NSDictionary *)accountInfo;
- (void)newAccountViewControllerCancelled:(NewAccountViewController *)controller;

@end

@interface NewAccountViewController : UITableViewController
    <ConnectionVerifierDelegate, UITextFieldDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
{
    NSUInteger accountType;
    UIBarButtonItem *cancelButtonItem;
    UIBarButtonItem *saveButtonItem;

    NSString *serverName;
    NSString *name;
    NSString *password;
    NSString *description;
    ConnectionVerifier *connectionVerifier;
    BOOL isVerified;
    BOOL isModified;
}

@property(nonatomic, retain) IBOutlet UIButton *linkButton;
@property(nonatomic, retain) NSDictionary *freshAccountInfo;
@property(nonatomic, assign) id <NewAccountDelegate> delegate;

- (IBAction)textFieldValueChanged:(id)sender;

- (IBAction)linkTouchUp:(id)sender;

@end
