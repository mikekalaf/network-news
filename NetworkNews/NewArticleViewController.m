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
#import "PostArticleOperation.h"
#import "AppDelegate.h"
#import "NetworkNews.h"
#import "NSString+NewsAdditions.h"

//#define RETURN_SYMBOL_CHAR      L'\u23ce'
//#define RETURN_SYMBOL_STR       @"\u23ce"
//#define RETURN_SYMBOL_LF_STR    @"\u23ce\n"
//
//#define PILCROW_SIGN_CHAR       L'\u00b6'
//#define PILCROW_SIGN_STR        @"\u00b6"
//#define PILCROW_SIGN_LF_STR     @"\u00b6\n"
//
//#define PARAGRAPH_SIGN_CHAR     PILCROW_SIGN_CHAR
//#define PARAGRAPH_SIGN_STR      PILCROW_SIGN_STR
//#define PARAGRAPH_SIGN_LF_STR   PILCROW_SIGN_LF_STR
#define EMPTY_STR               @""
//#define LF_STR                  @"\n"
//#define CR_STR                  @"\r"
//
//#define CACHE_FILE_NAME         @"new_post.txt"

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
    BOOL restoringText;
    NSRange restoredSelectedRange;
    NSOperationQueue *_operationQueue;
}

@property(nonatomic, weak) IBOutlet UIView *toView;
@property(nonatomic, weak) IBOutlet UIView *subjectView;
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
    
    // Set up the text view
    [self.view addSubview:_toView];
    [self.view addSubview:_subjectView];

    CGRect frame = _toView.frame;
    frame.origin.y = -100;
    frame.size.width = self.view.frame.size.width;
    _toView.frame = frame;
    _toView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    frame = _subjectView.frame;
    frame.origin.y = -100 + _toView.frame.size.height;
    frame.size.width = self.view.frame.size.width;
    _subjectView.frame = frame;
    _subjectView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    _toLabel.text = _groupName;
    _subjectTextField.text = _subject;

    [self textView].contentInset = UIEdgeInsetsMake(100, 0, 0, 0);
    
    // Do we have body text to load?
    if (_messageBody)
    {
//        // Add the paragraph signs to the supplied body text.  The supplied text
//        // is also likely to have CRFL pairs, so normalise this also.
//        NSString *text = [_messageBody stringByReplacingOccurrencesOfString:CR_STR
//                                                                 withString:EMPTY_STR];
//        text = [text stringByReplacingOccurrencesOfString:LF_STR
//                                               withString:PARAGRAPH_SIGN_LF_STR];
//        [[self textView] setText:text];
        [self textView].text = _messageBody;
    }

//    textView.text = @"\n\n\nAndnowasinglelinewithoutwordbreaksandwehavetohandlethissituationalsoespeciallywhenitcomestolinks.  This is a whole load of test text so we can test the word wrapping function.  Lets add a whole lot more to test things out.\n\nThis is a new paragraph.\nAndnowasinglelinewithoutwordbreaksandwehavetohandlethissituationalsoespeciallywhenitcomestolinks.\n";
//    textView.text = @"\n\n\nLorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";

    if (restoringText == NO)
    {
        // Append any default signature
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *sigText = [userDefaults stringForKey:@"Signature"];
        if (sigText && [sigText isEqualToString:EMPTY_STR] == NO)
        {
            NSString *signature = [NSString stringWithFormat:@"\n-- \n%@", sigText];
//            signature = [signature stringByReplacingOccurrencesOfString:LF_STR
//                                                             withString:PARAGRAPH_SIGN_LF_STR];
            [self textView].text = [[self textView].text stringByAppendingString:signature];
        }
    }
//    else
//    {
//        [textView becomeFirstResponder];
//        textView.selectedRange = restoredSelectedRange;
//    }
    
    // Notifications we're interested in
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
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

    if (_subjectTextField.text == nil)
        sendButtonItem.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Set the subject field as the first responder
//    if (_subject == nil || [_subject isEqualToString:EMPTY_STR])
//        [_subjectTextField becomeFirstResponder];
//    else
//        [[self view] becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [_operationQueue cancelAllOperations];

//    // Cache any text
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    [userDefaults setObject:subjectTextField.text
//                     forKey:@"MostRecentNewArticleSubject"];
//    [userDefaults setInteger:textView.selectedRange.location
//                      forKey:@"MostRecentNewArticleSelectedRangeLocation"];
//    
//    // Chop off the hacky three CRs at the beginning of the text
//    NSString *articleText = [textView.text substringFromIndex:3];
//
//    // Strip-out instances of paragraph sign
//    articleText = [articleText stringByReplacingOccurrencesOfString:PARAGRAPH_SIGN_STR
//                                                         withString:EMPTY_STR];
//
//    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    NSString *path = [appDelegate.cacheRootDir stringByAppendingPathComponent:CACHE_FILE_NAME];
//    [articleText writeToFile:path atomically:NO
//                    encoding:NSUTF8StringEncoding
//                       error:NULL];
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

    NNArticleFormatter *formatter = [[NNArticleFormatter alloc] init];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *name = [userDefaults stringForKey:@"FullName"];
    NSString *email = [userDefaults stringForKey:@"EmailAddress"];
    if (email == nil || [email isEqualToString:EMPTY_STR])
        email = @"unknown_user@invalid.com";
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
    NSString *newSubject = _subjectTextField.text;
    
    NSArray *headers = [NNArticleFormatter headerArrayWithDate:[NSDate date]
                                                          from:emailAddress
                                                       replyTo:replyToAddress
                                                  organization:organization
                                                     messageId:EMPTY_STR
                                                    references:_references
                                                    newsgroups:newsgroups
                                                       subject:newSubject];
    
    // Chop off the hacky three CRs at the beginning of the text
    NSString *articleText = [self textView].text;
    
    // Strip-out instances of paragraph sign
//    articleText = [articleText stringByReplacingOccurrencesOfString:PARAGRAPH_SIGN_STR
//                                                         withString:EMPTY_STR];

    // Word-wrap the text at column 78
    articleText = [articleText stringByWrappingWordsAtColumn:78];

    NSData *articleData = [formatter articleDataWithHeaders:headers
                                                       text:articleText
                                               formatFlowed:YES];
    
    PostArticleOperation *operation = [[PostArticleOperation alloc] initWithConnectionPool:_connectionPool
                                                                                      data:articleData];
    operation.completionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [activityIndicatorView stopAnimating];
            [_delegate newArticleViewController:self didSend:YES];
        });
    };
    [_operationQueue addOperation:operation];
}

#pragma mark -
#pragma mark Notifications

//- (void)articleNotPosted:(NSNotification *)notification
//{
//    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//    [nc removeObserver:self name:nil object:currentTask];
//    
//    [activityIndicatorView stopAnimating];
//    sendButtonItem.enabled = YES;
//    
//    NSString *errorString = [NSString stringWithFormat:
//                             @"Posting articles to the server \"%@\" is not allowed.",
//                             currentTask.connection.hostName];
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cannot Post"
//                                                        message:errorString
//                                                       delegate:nil
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//    [alertView show];
//
//    // We've finished our task
//    currentTask = nil;
//}
//
//- (void)articlePostError:(NSNotification *)notification
//{
//    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//    [nc removeObserver:self name:nil object:currentTask];
//
//    [activityIndicatorView stopAnimating];
//    sendButtonItem.enabled = YES;
//
//    AlertViewFailedConnection(currentTask.connection.hostName);
//
//    // We've finished our task
//    currentTask = nil;
//}

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
    NSValue *value = info[UIKeyboardBoundsUserInfoKey];
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
    NSValue *value = info[UIKeyboardBoundsUserInfoKey];
    CGSize keyboardSize = value.CGRectValue.size;
    
    // Reset the height of the scroll view to its original value
    CGRect frame = self.view.frame;
    frame.size.height += keyboardSize.height;
    self.view.frame = frame;
    
    keyboardShown = NO;
}

@end
