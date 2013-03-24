//
//  AccountSettingsViewController.m
//  Network News
//
//  Created by David Schweinsberg on 10/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "AccountSettingsViewController.h"
#import "NetworkNews.h"
#import "EditableTableViewCell.h"
#import "NewsAccount.h"
#import "ConnectionVerifier.h"

typedef enum {
    AccountSettingsNameTag,
    AccountSettingsHostTag,
    AccountSettingsUserNameTag,
    AccountSettingsPasswordTag,
    //AccountSettingsDescriptionTag,
} AccountSettingsTag;

@interface AccountSettingsViewController ()
{
    NSUInteger accountType;
    UIBarButtonItem *cancelButtonItem;
    UIBarButtonItem *saveButtonItem;
    BOOL isVerified;
    BOOL isModified;
    BOOL _isNameValid;
    NSMutableArray *_fields;
}

@property(nonatomic, weak) IBOutlet UIButton *linkButton;

- (IBAction)textFieldValueChanged:(id)sender;
- (IBAction)linkTouchUp:(id)sender;

- (UIView *)createVerifyView;
- (BOOL)selectNextField;

@end

@implementation AccountSettingsViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setTitle:[_account serviceName]];
    if ([_account supportURL])
        [_linkButton setTitle:[NSString stringWithFormat:
                               @"Learn More about %@",
                               [_account serviceName]]
                     forState:UIControlStateNormal];
    else
        [_linkButton setHidden:YES];

    // Cancel and Save buttons
    // We only want to display a cancel button if we're the root view controller
    if ([[self navigationController] viewControllers][0] == self)
    {
        cancelButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self
                                                      action:@selector(cancelButtonPressed:)];
        [[self navigationItem] setLeftBarButtonItem:cancelButtonItem];
    }

    saveButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                  target:self
                                                  action:@selector(saveButtonPressed:)];
    [saveButtonItem setEnabled:NO];
    [[self navigationItem] setRightBarButtonItem:saveButtonItem];

    _fields = [[NSMutableArray alloc] init];

    if ([_account accountTemplate] == AccountTemplateDefault)
    {
        [_fields addObject:@{
         @"tag": [NSNumber numberWithInteger:AccountSettingsHostTag],
         @"textLabel.text": @"Server",
         @"textField.text": [_account hostName] ? [_account hostName] : @"",
         @"textField.placeholder": @"Server address",
         @"textField.secureTextEntry": [NSNumber numberWithBool:NO],
         @"textField.keyboardType": [NSNumber numberWithInteger:UIKeyboardTypeDefault]}];
    }

    [_fields addObject:@{
     @"tag": [NSNumber numberWithInteger:AccountSettingsUserNameTag],
     @"textLabel.text": @"User Name",
     @"textField.text": [_account userName] ? [_account userName] : @"",
     @"textField.placeholder": @"username",
     @"textField.secureTextEntry": [NSNumber numberWithBool:NO],
     @"textField.keyboardType": [NSNumber numberWithInteger:UIKeyboardTypeDefault]}];

    [_fields addObject:@{
     @"tag": [NSNumber numberWithInteger:AccountSettingsPasswordTag],
     @"textLabel.text": @"Password",
     @"textField.text": [_account password] ? [_account password] : @"",
     @"textField.placeholder": @"optional",
     @"textField.secureTextEntry": [NSNumber numberWithBool:YES],
     @"textField.keyboardType": [NSNumber numberWithInteger:UIKeyboardTypeASCIICapable]}];

    [_fields addObject:@{
     @"tag": [NSNumber numberWithInteger:AccountSettingsNameTag],
     @"textLabel.text": @"Name",
     @"textField.text": [_account serviceName],
     @"textField.placeholder": @"required",
     @"textField.secureTextEntry": [NSNumber numberWithBool:NO],
     @"textField.keyboardType": [NSNumber numberWithInteger:UIKeyboardTypeDefault],
     @"validation": [NSValue valueWithPointer:@selector(isNameValid)]}];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        // Set the first field ready for entry
        [self selectNextField];
    }
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_fields count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        static NSString *cellIdentifier = @"Cell";
        EditableTableViewCell *cell = (EditableTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil)
        {
            cell = [[EditableTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                reuseIdentifier:cellIdentifier];
            [cell.textField addTarget:self
                               action:@selector(textFieldValueChanged:)
                     forControlEvents:UIControlEventEditingChanged];

            cell.textField.delegate = self;
            cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        }

        NSDictionary *field = _fields[[indexPath row]];
        cell.tag = [field[@"tag"] integerValue];
        [[cell textLabel] setText:field[@"textLabel.text"]];
        [[cell textField] setText:field[@"textField.text"]];
        [[cell textField] setPlaceholder:field[@"textField.placeholder"]];
        [[cell textField] setSecureTextEntry:[field[@"textField.secureTextEntry"] boolValue]];
        [[cell textField] setKeyboardType:[field[@"textField.keyboardType"] integerValue]];

        BOOL isValid = YES;
        NSValue *value = field[@"validation"];
        if (value)
        {
            SEL validationSelector = [value pointerValue];
            isValid = [[self performSelector:validationSelector] boolValue];
        }

        if (isValid)
            [[cell textField] setTextColor:[UIColor blackColor]];
        else
            [[cell textField] setTextColor:[UIColor redColor]];

        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForFooterInSection:(NSInteger)section
{
    if ([_linkButton isHidden])
        return 0;
    else
        return 72;
}

- (UIView *)tableView:(UITableView *)tableView
viewForFooterInSection:(NSInteger)section
{
    if ([_linkButton isHidden])
        return nil;
    else
        return _linkButton;
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Select the text field within the selected row
    EditableTableViewCell *cell = (EditableTableViewCell *)[[self tableView] cellForRowAtIndexPath:indexPath];
    [[cell textField] becomeFirstResponder];
}


#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)tableViewCell:(UITableViewCell *)tableViewCell enable:(BOOL)enable
{
    // There has to be a better way to gray-out the text fields, but we'll
    // go with this for now
    for (UIView *view in tableViewCell.contentView.subviews)
    {
        ((UIControl *)view).enabled = enable;
        if ([view isKindOfClass:[UITextField class]])
        {
            UITextField *textField = (UITextField *)view;
            if (enable)
                textField.textColor = [UIColor blackColor];
            else
                textField.textColor = [UIColor grayColor];
        }
    }
}

- (void)tableViewEnable:(BOOL)enable
{
    NSUInteger numberOfSections = self.tableView.numberOfSections;
    for (NSUInteger section = 0; section < numberOfSections; ++section)
    {
        NSUInteger numberOfRows = [self.tableView numberOfRowsInSection:section];
        for (NSUInteger row = 0; row < numberOfRows; ++row)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [self tableViewCell:cell enable:enable];
        }
    }
}

#pragma mark - Actions

- (IBAction)cancelButtonPressed:(id)sender
{
    [_delegate accountSettingsViewControllerCancelled:self];
}

- (IBAction)saveButtonPressed:(id)sender
{
    if (!isModified)
    {
        NSString *alertMessage = @"This account may not be able to send or receive news articles. Are you sure you want to save?";

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New Account"
                                                                message:alertMessage
                                                               delegate:self
                                                      cancelButtonTitle:@"Save"
                                                      otherButtonTitles:@"Edit", nil];
            [alertView show];
        }
        else
        {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:alertMessage
                                                                     delegate:self
                                                            cancelButtonTitle:@"Edit"
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:@"Save", nil];
            [actionSheet showInView:self.view];
        }
    }
    else if (!isVerified)
    {
        // Configure UI elements for verification
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationItem.titleView = [self createVerifyView];
        [self tableViewEnable:NO];

        [ConnectionVerifier verifyWithAccount:_account completion:^(BOOL connected, BOOL authenticated, BOOL verified) {

            isVerified = verified;
            isModified = NO;

            // Remove the "verifying" title
            [[self navigationItem] setTitleView:nil];

            if (verified)
            {
                // Tick-off the entries
                //        nameCell.accessoryType = UITableViewCellAccessoryCheckmark;
                //        passwordCell.accessoryType = UITableViewCellAccessoryCheckmark;

                // Report our success
                [_delegate accountSettingsViewController:self modifiedAccount:_account];
            }
            else
            {
                // Complain bitterly
                NSString *errorString;
                if (!connected)
                    errorString = [NSString stringWithFormat:
                                   @"The connection to \"%@\" failed",
                                   [_account hostName]];
                else if (!authenticated)
                    errorString = [NSString stringWithFormat:
                                   @"The user name or password for \"%@\" is incorrect",
                                   [_account hostName]];
                else
                    errorString = [NSString stringWithFormat:
                                   @"There was an unknown problem with \"%@\"",
                                   [_account hostName]];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cannot Get News"
                                                                    message:errorString
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
                
                // Restore UI elements for verification
                if (cancelButtonItem)
                    self.navigationItem.leftBarButtonItem = cancelButtonItem;
                self.navigationItem.rightBarButtonItem = saveButtonItem;
                [self tableViewEnable:YES];
            }
        }];
    }
    else
    {
    }
}

- (IBAction)textFieldValueChanged:(id)sender
{
    UITextField *textField = sender;
    NSUInteger tag = textField.superview.superview.tag;
    
    if (tag == AccountSettingsHostTag)
    {
        [_account setHostName:[textField text]];
    }
    else if (tag == AccountSettingsUserNameTag)
    {
        [_account setUserName:[textField text]];
    }
    else if (tag == AccountSettingsPasswordTag)
    {
        [_account setPassword:[textField text]];
    }
    else if (tag == AccountSettingsNameTag)
    {
        [_account setServiceName:[textField text]];
        [self isNameValid];
        if (_isNameValid)
            [textField setTextColor:[UIColor blackColor]];
        else
            [textField setTextColor:[UIColor redColor]];
    }
//    else if (tag == AccountSettingsDescriptionTag)
//    {
//        description = [textField.text copy];
//    }


    // Is the name unique? If not, disable save and display the name in red
    BOOL nameIsValid = [[self isNameValid] boolValue];

    if (nameIsValid)
    {
        if ([_account hostName] && [[_account hostName] length])
        {
            // If both the username and password fields have entries, then we can
            // enable the save button, otherwise it should be disabled
            if ([[_account userName] length] > 0 && [[_account password] length] > 0)
                [saveButtonItem setEnabled:YES];
            else
                [saveButtonItem setEnabled:NO];
        }
        else
        {
            if ([[_account hostName] length] > 0)
                [saveButtonItem setEnabled:YES];
            else
                [saveButtonItem setEnabled:NO];
        }
    }
    else
    {
        [saveButtonItem setEnabled:NO];
    }

    isModified = YES;
}

- (IBAction)linkTouchUp:(id)sender
{
    [[UIApplication sharedApplication] openURL:[_account supportURL]];
}

#pragma mark - UITextFieldDelegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Make sure the cell is selected
    UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (![indexPath isEqual:selectedIndexPath])
    {
        [self.tableView selectRowAtIndexPath:indexPath
                                    animated:NO
                              scrollPosition:UITableViewScrollPositionNone];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (![self selectNextField])
        [self saveButtonPressed:self];

    return YES;
}

#pragma mark - UIActionSheetDelegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet
didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        [_delegate accountSettingsViewController:self modifiedAccount:_account];
    }
}

#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView
didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        [_delegate accountSettingsViewController:self modifiedAccount:_account];
    }
}

#pragma mark - Private Methods

- (NSNumber *)isNameValid
{
    if ([[_account serviceName] length] == 0 ||
        [_delegate accountSettingsViewController:self verifyAccountName:[_account serviceName]] == NO)
        _isNameValid = NO;
    else
        _isNameValid = YES;
    return [NSNumber numberWithBool:_isNameValid];
}

- (UIView *)createVerifyView
{
    UIView *verifyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 142, 28)];
//    verifyView.backgroundColor = [UIColor grayColor];

    UIActivityIndicatorViewStyle style;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        style = UIActivityIndicatorViewStyleGray;
    else
        style = UIActivityIndicatorViewStyleWhite;
    
    UIActivityIndicatorView *activityView =
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
    CGRect frame = activityView.frame;
    frame.origin.y = 2;
    activityView.frame = frame;
    [activityView startAnimating];
    [verifyView addSubview:activityView];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(28, 0, 90, 24)];
    label.text = @"Verifying";
    label.font = [UIFont boldSystemFontOfSize:20];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        label.textColor = [UIColor grayColor];
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0, 1);
    }
    else
    {
        label.textColor = [UIColor whiteColor];
        label.shadowColor = [UIColor grayColor];
    }
    label.opaque = NO;
    label.backgroundColor = [UIColor clearColor];
    [verifyView addSubview:label];

    return verifyView;
}

- (BOOL)selectNextField
{
    // TODO: Upgrade this code to handle multiple sections

    NSUInteger rowCount = [self.tableView numberOfRowsInSection:0];

    NSIndexPath *indexPath;
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (!selectedIndexPath)
        indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    else if (selectedIndexPath.row < rowCount - 1)
        indexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row + 1
                                       inSection:0];
    else
        return NO;

    [self.tableView selectRowAtIndexPath:indexPath
                                animated:NO
                          scrollPosition:UITableViewScrollPositionBottom];
    
    EditableTableViewCell *cell = (EditableTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell.textField becomeFirstResponder];
    
    return YES;
}

@end
