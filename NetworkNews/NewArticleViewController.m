//
//  NewArticleViewController.m
//  Network News
//
//  Created by David Schweinsberg on 25/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NewArticleViewController.h"
#import "ActivityView.h"
#import "AppDelegate.h"
#import "EncodedWordEncoder.h"
#import "NNArticleFormatter.h"
#import "NSString+NewsAdditions.h"
#import "NetworkNews.h"
#import "NewsAccount.h"
#import "NewsConnection.h"
#import "NewsConnectionPool.h"
#import "PostArticleOperation.h"

#define EMPTY_STR @""

@interface NewArticleViewController () <UITextFieldDelegate> {
  UILabel *_groupNameLabel;
  UITextField *_subjectTextField;
  UIBarButtonItem *cancelButtonItem;
  UIBarButtonItem *sendButtonItem;
  ActivityView *activityView;
  NSString *_groupName;
  NSString *_subject;
  NSString *_references;
  NSString *_messageBody;
  BOOL keyboardShown;
  NSOperationQueue *_operationQueue;
}

@property(nonatomic, weak) IBOutlet UITextView *textView;

@end

@implementation NewArticleViewController

- (void)dealloc {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
}

- (void)setGroupName:(NSString *)groupName {
  _groupName = [groupName copy];
}

- (void)setSubject:(NSString *)subject {
  _subject = [subject copy];
}

- (void)setReferences:(NSString *)references {
  _references = [references copy];
}

- (void)setMessageBody:(NSString *)messageBody {
  _messageBody = [messageBody copy];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = @"New Article";

  _operationQueue = [[NSOperationQueue alloc] init];

  // Cancel and Send buttons
  cancelButtonItem = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                           target:self
                           action:@selector(cancelButtonPressed:)];
  self.navigationItem.leftBarButtonItem = cancelButtonItem;

  sendButtonItem =
      [[UIBarButtonItem alloc] initWithTitle:@"Send"
                                       style:UIBarButtonItemStyleDone
                                      target:self
                                      action:@selector(sendButtonPressed:)];
  self.navigationItem.rightBarButtonItem = sendButtonItem;

  // Add additional fields and views to the text box
  UILabel *toLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  //    toLabel.backgroundColor = UIColor.redColor;
  toLabel.text = @"To:";
  [self.textView addSubview:toLabel];
  toLabel.translatesAutoresizingMaskIntoConstraints = NO;
  NSLayoutConstraint *constraint;
  constraint = [NSLayoutConstraint constraintWithItem:toLabel
                                            attribute:NSLayoutAttributeTop
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:self.textView
                                            attribute:NSLayoutAttributeTop
                                           multiplier:1.0
                                             constant:8.0];
  [self.textView addConstraint:constraint];
  constraint = [NSLayoutConstraint constraintWithItem:toLabel
                                            attribute:NSLayoutAttributeLeading
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:self.textView
                                            attribute:NSLayoutAttributeLeading
                                           multiplier:1.0
                                             constant:4.0];
  [self.textView addConstraint:constraint];
  //    constraint = [NSLayoutConstraint constraintWithItem:toLabel
  //                                              attribute:NSLayoutAttributeWidth
  //                                              relatedBy:NSLayoutRelationEqual
  //                                                 toItem:nil
  //                                              attribute:0
  //                                             multiplier:1.0
  //                                               constant:50.0];
  //    [toLabel addConstraint:constraint];

  _groupNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  //    _groupNameLabel.backgroundColor = UIColor.blueColor;
  [self.textView addSubview:_groupNameLabel];
  _groupNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
  constraint = [NSLayoutConstraint constraintWithItem:_groupNameLabel
                                            attribute:NSLayoutAttributeLeading
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:toLabel
                                            attribute:NSLayoutAttributeTrailing
                                           multiplier:1.0
                                             constant:8.0];
  [self.textView addConstraint:constraint];
  constraint = [NSLayoutConstraint constraintWithItem:_groupNameLabel
                                            attribute:NSLayoutAttributeBaseline
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:toLabel
                                            attribute:NSLayoutAttributeBaseline
                                           multiplier:1.0
                                             constant:0.0];
  [self.textView addConstraint:constraint];

  UILabel *fromLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  //    fromLabel.backgroundColor = UIColor.redColor;
  fromLabel.text = @"From:";
  [self.textView addSubview:fromLabel];
  fromLabel.translatesAutoresizingMaskIntoConstraints = NO;
  constraint = [NSLayoutConstraint constraintWithItem:fromLabel
                                            attribute:NSLayoutAttributeTop
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:toLabel
                                            attribute:NSLayoutAttributeBottom
                                           multiplier:1.0
                                             constant:8.0];
  [self.textView addConstraint:constraint];
  constraint = [NSLayoutConstraint constraintWithItem:fromLabel
                                            attribute:NSLayoutAttributeLeading
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:self.textView
                                            attribute:NSLayoutAttributeLeading
                                           multiplier:1.0
                                             constant:4.0];
  [self.textView addConstraint:constraint];

  _subjectTextField = [[UITextField alloc] initWithFrame:CGRectZero];
  //    _subjectTextField.borderStyle = UITextBorderStyleLine;
  //    _subjectTextField.backgroundColor = UIColor.blueColor;
  _subjectTextField.text = @"Subject";
  [self.textView addSubview:_subjectTextField];
  _subjectTextField.translatesAutoresizingMaskIntoConstraints = NO;
  constraint = [NSLayoutConstraint constraintWithItem:_subjectTextField
                                            attribute:NSLayoutAttributeLeading
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:fromLabel
                                            attribute:NSLayoutAttributeTrailing
                                           multiplier:1.0
                                             constant:8.0];
  [self.textView addConstraint:constraint];
  constraint = [NSLayoutConstraint constraintWithItem:_subjectTextField
                                            attribute:NSLayoutAttributeBaseline
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:fromLabel
                                            attribute:NSLayoutAttributeBaseline
                                           multiplier:1.0
                                             constant:0.0];
  [self.textView addConstraint:constraint];
  //    constraint = [NSLayoutConstraint constraintWithItem:_subjectTextField
  //                                              attribute:NSLayoutAttributeTrailing
  //                                              relatedBy:NSLayoutRelationEqual
  //                                                 toItem:self.textView
  //                                              attribute:NSLayoutAttributeTrailing
  //                                             multiplier:1.0
  //                                               constant:0.0];
  //    [self.textView addConstraint:constraint];
  constraint = [NSLayoutConstraint constraintWithItem:_subjectTextField
                                            attribute:NSLayoutAttributeWidth
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:nil
                                            attribute:0
                                           multiplier:1.0
                                             constant:250.0];
  [_subjectTextField addConstraint:constraint];

  // Create an activity indicator
  activityView = [[ActivityView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
  activityView.hidden = YES;
  [self.view addSubview:activityView];

  _groupNameLabel.text = _groupName;
  _subjectTextField.text = _subject;

  self.textView.textContainerInset = UIEdgeInsetsMake(70, 0, 8, 0);

  // Do we have body text to load?
  if (_messageBody)
    self.textView.text = _messageBody;

  // Append any default signature
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSString *sigText = [userDefaults stringForKey:@"Signature"];
  if (sigText && [sigText isEqualToString:EMPTY_STR] == NO) {
    NSString *signature = [NSString stringWithFormat:@"\n-- \n%@", sigText];
    self.textView.text = [self.textView.text stringByAppendingString:signature];
  }

  // Notifications we're interested in
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(postArticleCompleted:)
             name:PostArticleCompletedNotification
           object:nil];
  [nc addObserver:self
         selector:@selector(subjectDidChange:)
             name:UITextFieldTextDidChangeNotification
           object:_subjectTextField];
  [nc addObserver:self
         selector:@selector(keyboardDidShow:)
             name:UIKeyboardDidShowNotification
           object:nil];
  [nc addObserver:self
         selector:@selector(keyboardWillHide:)
             name:UIKeyboardWillHideNotification
           object:nil];

  if (_subjectTextField.text.length == 0)
    sendButtonItem.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  // Set the subject field as the first responder
  if (_subject == nil || [_subject isEqualToString:EMPTY_STR])
    [_subjectTextField becomeFirstResponder];
  else
    [self.view becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [_operationQueue cancelAllOperations];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  activityView.center = self.navigationController.view.center;
}

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];

  // Release any cached data, images, etc that aren't in use.
}

#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  // Make the text view the first responder and position the cursor at
  // the top
  [self.textView becomeFirstResponder];
  self.textView.selectedRange = NSMakeRange(0, 0);

  return NO;
}

#pragma mark - Actions

- (IBAction)cancelButtonPressed:(id)sender {
  [_delegate newArticleViewController:self didSend:NO];
}

- (IBAction)sendButtonPressed:(id)sender {
  sendButtonItem.enabled = NO;
  [self.textView resignFirstResponder];
  self->activityView.hidden = NO;

  EncodedWordEncoder *encoder = [[EncodedWordEncoder alloc] init];

  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSString *name = [userDefaults stringForKey:@"FullName"];
  NSString *email = [userDefaults stringForKey:@"EmailAddress"];
  if (email == nil || [email isEqualToString:EMPTY_STR])
    email = @"unknown_user@invalid.com";
  //    name = [encoder encodeString:@"Føø Bår"];
  //    name = [encoder encodeString:@"Tésting"];
  NSString *emailAddress;
  if (name && [name isEqualToString:EMPTY_STR] == NO)
    emailAddress = [NSString stringWithFormat:@"%@ <%@>", name, email];
  else
    emailAddress = email;

  NSString *replyTo = [userDefaults stringForKey:@"ReplyTo"];
  NSString *replyToAddress = nil;
  if (replyTo && [replyTo isEqualToString:EMPTY_STR] == NO)
    replyToAddress = [NSString stringWithFormat:@"%@ <%@>", name, replyTo];

  NSString *organization = [userDefaults stringForKey:@"Organization"];

  NSString *newsgroups = _groupNameLabel.text;
  NSString *newSubject = [encoder encodeString:_subjectTextField.text];

  NSArray *headers = [NNArticleFormatter headerArrayWithDate:[NSDate date]
                                                        from:emailAddress
                                                     replyTo:replyToAddress
                                                organization:organization
                                                   messageId:EMPTY_STR
                                                  references:_references
                                                  newsgroups:newsgroups
                                                     subject:newSubject];

  NSString *articleText = self.textView.text;

  // Word-wrap the text at column 78
  articleText = [articleText stringByWrappingUnquotedWordsAtColumn:78];

  NSData *articleData = [NNArticleFormatter articleDataWithHeaders:headers
                                                              text:articleText
                                                      formatFlowed:YES];

  PostArticleOperation *operation =
      [[PostArticleOperation alloc] initWithConnectionPool:_connectionPool
                                                      data:articleData];
  operation.completionBlock = ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      self->activityView.hidden = YES;
    });
  };
  [_operationQueue addOperation:operation];
}

#pragma mark - Notifications

- (void)postArticleCompleted:(NSNotification *)notification {
  NSInteger statusCode = [notification.userInfo[@"statusCode"] integerValue];
  if (statusCode == 240) {
    // Article posted
    [self->_delegate newArticleViewController:self didSend:YES];
  } else {
    NSString *response = notification.userInfo[@"response"];
    NSString *message =
        [NSString stringWithFormat:@"Post failed with message: %@", response];
    dispatch_async(dispatch_get_main_queue(), ^{
      UIAlertController *alert = [UIAlertController
          alertControllerWithTitle:@"Error"
                           message:message
                    preferredStyle:UIAlertControllerStyleAlert];
      UIAlertAction *defaultAction = [UIAlertAction
          actionWithTitle:@"OK"
                    style:UIAlertActionStyleDefault
                  handler:^(UIAlertAction *action){
                      //                                                                      [self->_delegate newArticleViewController:self didSend:NO];
                  }];
      [alert addAction:defaultAction];
      [self presentViewController:alert animated:YES completion:nil];
    });
  }
}

- (void)subjectDidChange:(NSNotification *)notification {
  if (_subjectTextField.text.length > 0)
    sendButtonItem.enabled = YES;
  else
    sendButtonItem.enabled = NO;
}

- (void)keyboardDidShow:(NSNotification *)notification {
  UIViewController *parent = self.parentViewController;
  CGRect parentFrame = parent.view.frame;

  // Get the size of the keyboard
  NSDictionary *info = notification.userInfo;
  NSValue *value = info[UIKeyboardFrameEndUserInfoKey];
  CGSize keyboardSize = value.CGRectValue.size;

  // Resize the root view
  CGRect frame = self.view.frame;
  frame.size.height = parentFrame.size.height - keyboardSize.height;
  self.view.frame = frame;
}

- (void)keyboardWillHide:(NSNotification *)notification {
  UIViewController *parent = self.parentViewController;
  CGRect parentFrame = parent.view.frame;

  // Resize the root view
  CGRect frame = self.view.frame;
  frame.size.height = parentFrame.size.height;
  self.view.frame = frame;
}

@end
