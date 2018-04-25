//
//  NewArticleViewController.m
//  Network News
//
//  Created by David Schweinsberg on 25/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NewArticleViewController.h"
#import "NNArticleFormatter.h"
#import "NewsConnectionPool.h"
#import "NewsConnection.h"
#import "NewsAccount.h"
#import "PostArticleOperation.h"
#import "AppDelegate.h"
#import "NetworkNews.h"
#import "NSString+NewsAdditions.h"
#import "EncodedWordEncoder.h"

#define EMPTY_STR @""

@interface NewArticleViewController () <UITextFieldDelegate, UITextViewDelegate>
{
    UIBarButtonItem *cancelButtonItem;
    UIBarButtonItem *sendButtonItem;
    UIActivityIndicatorView *activityIndicatorView;
    NSString *_groupName;
    NSString *_subject;
    NSString *_references;
    NSString *_messageBody;
    BOOL keyboardShown;
    NSOperationQueue *_operationQueue;
}

@property(nonatomic, weak) IBOutlet UILabel *toLabel;
@property(nonatomic, weak) IBOutlet UITextField *subjectTextField;

@end


@implementation NewArticleViewController

- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

- (UITextView *)textView
{
    return (UITextView *)self.view;
}

- (void)setGroupName:(NSString *)groupName
{
    _groupName = [groupName copy];
}

- (void)setSubject:(NSString *)subject
{
    _subject = [subject copy];
}

- (void)setReferences:(NSString *)references
{
    _references = [references copy];
}

- (void)setMessageBody:(NSString *)messageBody
{
    _messageBody = [messageBody copy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"New Article";

    _operationQueue = [[NSOperationQueue alloc] init];
    
    // Cancel and Send buttons
    cancelButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                  target:self
                                                  action:@selector(cancelButtonPressed:)];
    self.navigationItem.leftBarButtonItem = cancelButtonItem;
    
    sendButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Send"
                                     style:UIBarButtonItemStyleDone
                                    target:self
                                    action:@selector(sendButtonPressed:)];
    self.navigationItem.rightBarButtonItem = sendButtonItem;

    // Create an activity indicator
    activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.hidesWhenStopped = YES;
    [self.view addSubview:activityIndicatorView];
    activityIndicatorView.center = self.view.center;
    
    _toLabel.text = _groupName;
    _subjectTextField.text = _subject;

    [self textView].textContainerInset = UIEdgeInsetsMake(100, 0, 8, 0);

    // Do we have body text to load?
    if (_messageBody)
    {
//        // Add the paragraph signs to the supplied body text.  The supplied text
//        // is also likely to have CRLF pairs, so normalise this also.
//        NSString *text = [_messageBody stringByReplacingOccurrencesOfString:CR_STR
//                                                                 withString:EMPTY_STR];
//        text = [text stringByReplacingOccurrencesOfString:LF_STR
//                                               withString:PARAGRAPH_SIGN_LF_STR];
//        [[self textView] setText:text];
        [self textView].text = _messageBody;
    }

    if (self.textView.text.length == 0)
    {
//    textView.text = @"\n\n\nAndnowasinglelinewithoutwordbreaksandwehavetohandlethissituationalsoespeciallywhenitcomestolinks.  This is a whole load of test text so we can test the word wrapping function.  Lets add a whole lot more to test things out.\n\nThis is a new paragraph.\nAndnowasinglelinewithoutwordbreaksandwehavetohandlethissituationalsoespeciallywhenitcomestolinks.\n";
        self.textView.text = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";
    }

    // Append any default signature
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *sigText = [userDefaults stringForKey:@"Signature"];
    if (sigText && [sigText isEqualToString:EMPTY_STR] == NO)
    {
        NSString *signature = [NSString stringWithFormat:@"\n-- \n%@", sigText];
        [self textView].text = [[self textView].text stringByAppendingString:signature];
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
           selector:@selector(keyboardDidHide:)
               name:UIKeyboardDidHideNotification
             object:nil];

    if (_subjectTextField.text.length == 0)
        sendButtonItem.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Set the subject field as the first responder
    if (_subject == nil || [_subject isEqualToString:EMPTY_STR])
        [_subjectTextField becomeFirstResponder];
    else
        [self.view becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_operationQueue cancelAllOperations];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark -
#pragma mark UITextViewDelegate Methods

//- (void)textViewDidChangeSelection:(UITextView *)aTextView
//{
//    NSRange range = aTextView.selectedRange;
//    if (range.location == 0x7fffffff)
//        return;
//    
//    if (restoringText)
//    {
//        restoringText = NO;
//        _textView.selectedRange = restoredSelectedRange;
//        return;
//    }
//
//    // Make sure the selection does not start to the right of a paragraph sign
//    if (range.location > 0
//        && [aTextView.text characterAtIndex:range.location - 1] == PARAGRAPH_SIGN_CHAR)
//    {
//        // Adjust the range to the left
//        --range.location;
//        if (range.length > 0)
//            ++range.length;
//        
//        aTextView.selectedRange = range;
//    }
//}
//
//- (BOOL)textView:(UITextView *)aTextView
//shouldChangeTextInRange:(NSRange)range
// replacementText:(NSString *)text
//{
//    // Refuse to allow the first three characters to be edited
//    NSRange headerRange = NSMakeRange(0, 3);
//    if (NSLocationInRange(range.location, headerRange))
//        return NO;
//    
//    if ([text isEqualToString:LF_STR])
//    {
//        // Include a paragraph sign for hard line breaks
//        NSMutableString *mutableText = [aTextView.text mutableCopy];
//        [mutableText replaceCharactersInRange:range withString:PARAGRAPH_SIGN_LF_STR];
//
//        // Lock the scroller as when we set the text, the selection point is
//        // moved to the end of the text.  We may need to bring it back, so we
//        // want to prevent the scroll-to-end occuring.
//        aTextView.scrollEnabled = NO;
//        aTextView.text = mutableText;
//        
//        // If text has been inserted, we need to restore the selectedRange
//        if (aTextView.selectedRange.location != range.location + 2)
//            aTextView.selectedRange = NSMakeRange(range.location + 2, 0);
//        
//        // Now re-enable the scroller, and manually scroll to the selection point
//        aTextView.scrollEnabled = YES;
//        [aTextView scrollRangeToVisible:NSMakeRange(aTextView.selectedRange.location, 1)];
//
//        return NO;
//    }
//    else if ([text isEqualToString:EMPTY_STR])
//    {
//        // This is a deletion, so we must check if the first character in the
//        // range is a new-line.  If so, we must also delete the corresponding
//        // paragraph sign
//        if ([aTextView.text characterAtIndex:range.location] == L'\n')
//        {
//            NSMutableString *mutableText = [aTextView.text mutableCopy];
//            range.location -= 1;
//            range.length += 1;
//            [mutableText deleteCharactersInRange:range];
//
//            aTextView.scrollEnabled = NO;
//            aTextView.text = mutableText;
//
//            // Do we need to restore the selectedRange?
//            if (aTextView.selectedRange.location != range.location)
//                aTextView.selectedRange = NSMakeRange(range.location, 0);
//
//            aTextView.scrollEnabled = YES;
//            [aTextView scrollRangeToVisible:NSMakeRange(aTextView.selectedRange.location, 1)];
//
//            return NO;
//        }
//        else if ([aTextView.text characterAtIndex:range.location] == PARAGRAPH_SIGN_CHAR)
//        {
//            NSMutableString *mutableText = [aTextView.text mutableCopy];
//            range.length += 1;
//            [mutableText deleteCharactersInRange:range];
//
//            aTextView.scrollEnabled = NO;
//            aTextView.text = mutableText;
//
//            // Do we need to restore the selectedRange?
//            if (aTextView.selectedRange.location != range.location)
//            {
//                NSLog(@"YIPPEE!");
//                aTextView.selectedRange = NSMakeRange(range.location, 0);
//            }
//
//            aTextView.scrollEnabled = YES;
//            [aTextView scrollRangeToVisible:NSMakeRange(aTextView.selectedRange.location, 1)];
//
//            return NO;
//        }
//    }
//    else if (text.length > 1)
//    {
//        // Pasting text -- insert paragraph signs (if needed) into the supplied text
//        // (This is also called when autocorrecting)
//
//        // If we're pasting text that we've copied from a NewArticleView, then
//        // we'll need to strip out the paragraph signs first... before putting
//        // them back in.
//        NSString *replacementText = [text stringByReplacingOccurrencesOfString:PARAGRAPH_SIGN_STR
//                                                                    withString:EMPTY_STR];
//
//        replacementText = [replacementText stringByReplacingOccurrencesOfString:LF_STR
//                                                                     withString:PARAGRAPH_SIGN_LF_STR];
//
//        NSMutableString *mutableText = [aTextView.text mutableCopy];
//        [mutableText replaceCharactersInRange:range withString:replacementText];
//
//        aTextView.scrollEnabled = NO;
//        aTextView.text = mutableText;
//
//        // Do we need to restore the selectedRange?
//        if (aTextView.selectedRange.location != range.location + replacementText.length)
//            aTextView.selectedRange = NSMakeRange(range.location + replacementText.length, 0);
//
//        aTextView.scrollEnabled = YES;
//        [aTextView scrollRangeToVisible:NSMakeRange(aTextView.selectedRange.location, 1)];
//
//        return NO;
//    }
//    
//    return YES;
//}

#pragma mark -
#pragma mark UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Make the text view the first responder and position the cursor at
    // the top
    [[self textView] becomeFirstResponder];
    [self textView].selectedRange = NSMakeRange(0, 0);
    
    return NO;
}

#pragma mark -
#pragma mark Actions

- (IBAction)cancelButtonPressed:(id)sender
{
    [_delegate newArticleViewController:self didSend:NO];
}

- (IBAction)sendButtonPressed:(id)sender
{
    sendButtonItem.enabled = NO;
    [[self textView] resignFirstResponder];
    [activityIndicatorView startAnimating];

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
    
    NSString *newsgroups = _toLabel.text;
    NSString *newSubject = [encoder encodeString:_subjectTextField.text];
    
    NSArray *headers = [NNArticleFormatter headerArrayWithDate:[NSDate date]
                                                          from:emailAddress
                                                       replyTo:replyToAddress
                                                  organization:organization
                                                     messageId:EMPTY_STR
                                                    references:_references
                                                    newsgroups:newsgroups
                                                       subject:newSubject];
    
    NSString *articleText = [self textView].text;
    
    // Word-wrap the text at column 78
    articleText = [articleText stringByWrappingUnquotedWordsAtColumn:78];

    NSData *articleData = [NNArticleFormatter articleDataWithHeaders:headers
                                                                text:articleText
                                                        formatFlowed:YES];
    
    PostArticleOperation *operation = [[PostArticleOperation alloc] initWithConnectionPool:_connectionPool
                                                                                      data:articleData];
    operation.completionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->activityIndicatorView stopAnimating];
        });
    };
    [_operationQueue addOperation:operation];
}

#pragma mark - Notifications

- (void)postArticleCompleted:(NSNotification *)notification
{
    NSInteger statusCode = [notification.userInfo[@"statusCode"] integerValue];
    if (statusCode == 240)
    {
        // Article posted
        [self->_delegate newArticleViewController:self didSend:YES];
    }
    else
    {
        NSString *response = notification.userInfo[@"response"];
        NSString *message = [NSString stringWithFormat:
                             @"Post failed with message: %@",
                             response];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
//                                                                      [self->_delegate newArticleViewController:self didSend:NO];
                                                                 }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
}

- (void)subjectDidChange:(NSNotification *)notification
{
    if (_subjectTextField.text.length > 0)
        sendButtonItem.enabled = YES;
    else
        sendButtonItem.enabled = NO;
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    if (keyboardShown)
        return;
    
    NSDictionary *info = notification.userInfo;
    
    // Get the size of the keyboard
    NSValue *value = info[UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = value.CGRectValue.size;
    
    // Resize the text view
    CGRect frame = self.view.frame;
    frame.size.height -= keyboardSize.height;
    self.view.frame = frame;
    
    keyboardShown = YES;
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    
    // Get the size of the keyboard
    NSValue *value = info[UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = value.CGRectValue.size;
    
    // Reset the height of the scroll view to its original value
    CGRect frame = self.view.frame;
    frame.size.height += keyboardSize.height;
    self.view.frame = frame;
    
    keyboardShown = NO;
}

@end
