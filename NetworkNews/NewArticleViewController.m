//
//  NewArticleViewController.m
//  Network News
//
//  Created by David Schweinsberg on 25/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NewArticleViewController.h"
#import "NNArticleFormatter.h"
#import "NNConnection.h"
#import "PostArticleTask.h"
#import "NetworkNewsAppDelegate.h"
#import "NetworkNews.h"
#import "NSString+NewsAdditions.h"

#define RETURN_SYMBOL_CHAR      L'\u23ce'
#define RETURN_SYMBOL_STR       @"\u23ce"
#define RETURN_SYMBOL_LF_STR    @"\u23ce\n"

#define PILCROW_SIGN_CHAR       L'\u00b6'
#define PILCROW_SIGN_STR        @"\u00b6"
#define PILCROW_SIGN_LF_STR     @"\u00b6\n"

#define PARAGRAPH_SIGN_CHAR     PILCROW_SIGN_CHAR
#define PARAGRAPH_SIGN_STR      PILCROW_SIGN_STR
#define PARAGRAPH_SIGN_LF_STR   PILCROW_SIGN_LF_STR
#define EMPTY_STR               @""
#define LF_STR                  @"\n"
#define CR_STR                  @"\r"

#define CACHE_FILE_NAME         @"new_post.txt"

@implementation NewArticleViewController

@synthesize textView;
@synthesize toView;
@synthesize subjectView;
@synthesize toLabel;
@synthesize subjectTextField;
@synthesize delegate;

- (id)initWithGroupName:(NSString *)aGroupName
                subject:(NSString *)aSubject
             references:(NSString *)aReferences
               bodyText:(NSString *)aBodyText
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        self = [super initWithNibName:@"NewArticleView-iPad" bundle:nil];
    else
        self = [super initWithNibName:@"NewArticleView" bundle:nil];
    if (self)
    {
        groupName = [aGroupName copy];
        subject = [aSubject copy];
        references = [aReferences copy];
        bodyText = aBodyText;
    }
    return self;
}

- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"New Article";
    
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
    [textView addSubview:toView];
    [textView addSubview:subjectView];
    
    CGRect frame = toView.frame;
    frame.size.width = textView.frame.size.width;
    toView.frame = frame;
    
    frame = subjectView.frame;
    frame.origin.y = toView.frame.size.height;
    frame.size.width = textView.frame.size.width;
    subjectView.frame = frame;
    
    toLabel.text = groupName;
    subjectTextField.text = subject;
    textView.text = @"\n\n\n";
    
    // Do we have body text to load?
    if (bodyText)
    {
        // Add the paragraph signs to the supplied body text (not forgetting
        // to add the cursed hacky prefix of 3 line feeds).  The supplied text
        // is also likely to have CRFL pairs, so normalise this also.
        NSString *hackyPrefix = @"\n\n\n";
        NSString *text = [bodyText stringByReplacingOccurrencesOfString:CR_STR
                                                             withString:EMPTY_STR];
        text = [text stringByReplacingOccurrencesOfString:LF_STR
                                               withString:PARAGRAPH_SIGN_LF_STR];
        textView.text = [hackyPrefix stringByAppendingString:text];
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
            signature = [signature stringByReplacingOccurrencesOfString:LF_STR
                                                             withString:PARAGRAPH_SIGN_LF_STR];
            textView.text = [textView.text stringByAppendingString:signature];
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
             object:subjectTextField];
    [nc addObserver:self
           selector:@selector(keyboardDidShow:)
               name:UIKeyboardDidShowNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(keyboardDidHide:)
               name:UIKeyboardDidHideNotification
             object:nil];
    
    if (subjectTextField.text == nil)
        sendButtonItem.enabled = NO;

//    if (restoringText == NO)
//    {
        // Set the subject field as the first responder
        if (subject == nil || [subject isEqualToString:EMPTY_STR])
            [subjectTextField becomeFirstResponder];
        else
            [textView becomeFirstResponder];
//    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // Cancel any live task/connection
    if (currentTask)
    {
        [currentTask cancel];
        currentTask = nil;
    }
    
    // Cache any text
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:subjectTextField.text
                     forKey:@"MostRecentNewArticleSubject"];
    [userDefaults setInteger:textView.selectedRange.location
                      forKey:@"MostRecentNewArticleSelectedRangeLocation"];
    
    // Chop off the hacky three CRs at the beginning of the text
    NSString *articleText = [textView.text substringFromIndex:3];

    // Strip-out instances of paragraph sign
    articleText = [articleText stringByReplacingOccurrencesOfString:PARAGRAPH_SIGN_STR
                                                         withString:EMPTY_STR];

    NetworkNewsAppDelegate *appDelegate = (NetworkNewsAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *path = [appDelegate.cacheRootDir stringByAppendingPathComponent:CACHE_FILE_NAME];
    [articleText writeToFile:path atomically:NO
                    encoding:NSUTF8StringEncoding
                       error:NULL];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Resize the field views
    float textViewWidth = textView.frame.size.width;
    CGRect frame = toView.frame;
    frame.size.width = textViewWidth;
    toView.frame = frame;

    frame = toLabel.frame;
    frame.size.width = textViewWidth - frame.origin.x - 8;
    toLabel.frame = frame;
    
    frame = subjectView.frame;
    frame.origin.y = toView.frame.size.height;
    frame.size.width = textViewWidth;
    subjectView.frame = frame;
    
    frame = subjectTextField.frame;
    frame.size.width = textViewWidth - frame.origin.x - 8;
    subjectTextField.frame = frame;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark -
#pragma mark Public Methods

- (void)restoreLevel
{
    // Restore any text from the cache
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    subject = [userDefaults objectForKey:@"MostRecentNewArticleSubject"];
    restoredSelectedRange.location = [userDefaults integerForKey:@"MostRecentNewArticleSelectedRangeLocation"];
    restoredSelectedRange.length = 0;

    NetworkNewsAppDelegate *appDelegate = (NetworkNewsAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *path = [appDelegate.cacheRootDir stringByAppendingPathComponent:CACHE_FILE_NAME];
    bodyText = [NSString stringWithContentsOfFile:path
                                         encoding:NSUTF8StringEncoding
                                            error:NULL];
    restoringText = YES;
}

#pragma mark -
#pragma mark UITextViewDelegate Methods

- (void)textViewDidChangeSelection:(UITextView *)aTextView
{
    NSRange range = aTextView.selectedRange;
    if (range.location == 0x7fffffff)
        return;
    
    if (restoringText)
    {
        restoringText = NO;
        textView.selectedRange = restoredSelectedRange;
        return;
    }

    // Make sure the selection does not start to the right of a paragraph sign
    if (range.location > 0
        && [aTextView.text characterAtIndex:range.location - 1] == PARAGRAPH_SIGN_CHAR)
    {
        // Adjust the range to the left
        --range.location;
        if (range.length > 0)
            ++range.length;
        
        aTextView.selectedRange = range;
    }
}

- (BOOL)textView:(UITextView *)aTextView
shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text
{
    // Refuse to allow the first three characters to be edited
    NSRange headerRange = NSMakeRange(0, 3);
    if (NSLocationInRange(range.location, headerRange))
        return NO;
    
    if ([text isEqualToString:LF_STR])
    {
        // Include a paragraph sign for hard line breaks
        NSMutableString *mutableText = [aTextView.text mutableCopy];
        [mutableText replaceCharactersInRange:range withString:PARAGRAPH_SIGN_LF_STR];

        // Lock the scroller as when we set the text, the selection point is
        // moved to the end of the text.  We may need to bring it back, so we
        // want to prevent the scroll-to-end occuring.
        aTextView.scrollEnabled = NO;
        aTextView.text = mutableText;
        
        // If text has been inserted, we need to restore the selectedRange
        if (aTextView.selectedRange.location != range.location + 2)
            aTextView.selectedRange = NSMakeRange(range.location + 2, 0);
        
        // Now re-enable the scroller, and manually scroll to the selection point
        aTextView.scrollEnabled = YES;
        [aTextView scrollRangeToVisible:NSMakeRange(aTextView.selectedRange.location, 1)];

        return NO;
    }
    else if ([text isEqualToString:EMPTY_STR])
    {
        // This is a deletion, so we must check if the first character in the
        // range is a new-line.  If so, we must also delete the corresponding
        // paragraph sign
        if ([aTextView.text characterAtIndex:range.location] == L'\n')
        {
            NSMutableString *mutableText = [aTextView.text mutableCopy];
            range.location -= 1;
            range.length += 1;
            [mutableText deleteCharactersInRange:range];

            aTextView.scrollEnabled = NO;
            aTextView.text = mutableText;

            // Do we need to restore the selectedRange?
            if (aTextView.selectedRange.location != range.location)
                aTextView.selectedRange = NSMakeRange(range.location, 0);

            aTextView.scrollEnabled = YES;
            [aTextView scrollRangeToVisible:NSMakeRange(aTextView.selectedRange.location, 1)];

            return NO;
        }
        else if ([aTextView.text characterAtIndex:range.location] == PARAGRAPH_SIGN_CHAR)
        {
            NSMutableString *mutableText = [aTextView.text mutableCopy];
            range.length += 1;
            [mutableText deleteCharactersInRange:range];

            aTextView.scrollEnabled = NO;
            aTextView.text = mutableText;

            // Do we need to restore the selectedRange?
            if (aTextView.selectedRange.location != range.location)
            {
                NSLog(@"YIPPEE!");
                aTextView.selectedRange = NSMakeRange(range.location, 0);
            }

            aTextView.scrollEnabled = YES;
            [aTextView scrollRangeToVisible:NSMakeRange(aTextView.selectedRange.location, 1)];

            return NO;
        }
    }
    else if (text.length > 1)
    {
        // Pasting text -- insert paragraph signs (if needed) into the supplied text
        // (This is also called when autocorrecting)

        // If we're pasting text that we've copied from a NewArticleView, then
        // we'll need to strip out the paragraph signs first... before putting
        // them back in.
        NSString *replacementText = [text stringByReplacingOccurrencesOfString:PARAGRAPH_SIGN_STR
                                                                    withString:EMPTY_STR];

        replacementText = [replacementText stringByReplacingOccurrencesOfString:LF_STR
                                                                     withString:PARAGRAPH_SIGN_LF_STR];

        NSMutableString *mutableText = [aTextView.text mutableCopy];
        [mutableText replaceCharactersInRange:range withString:replacementText];

        aTextView.scrollEnabled = NO;
        aTextView.text = mutableText;

        // Do we need to restore the selectedRange?
        if (aTextView.selectedRange.location != range.location + replacementText.length)
            aTextView.selectedRange = NSMakeRange(range.location + replacementText.length, 0);

        aTextView.scrollEnabled = YES;
        [aTextView scrollRangeToVisible:NSMakeRange(aTextView.selectedRange.location, 1)];

        return NO;
    }
    
    return YES;
}

#pragma mark -
#pragma mark UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Make the text view the first responder and position the cursor at
    // the top
    [textView becomeFirstResponder];
    textView.selectedRange = NSMakeRange(3, 0);
    
    return NO;
}

#pragma mark -
#pragma mark Actions

- (IBAction)cancelButtonPressed:(id)sender
{
    [delegate newArticleViewController:self didSend:NO];
}

- (IBAction)sendButtonPressed:(id)sender
{
    sendButtonItem.enabled = NO;
    [textView resignFirstResponder];
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
    
    NSString *newsgroups = toLabel.text;
    NSString *newSubject = subjectTextField.text;
    
    NSArray *headers = [NNArticleFormatter headerArrayWithDate:[NSDate date]
                                                          from:emailAddress
                                                       replyTo:replyToAddress
                                                  organization:organization
                                                     messageId:EMPTY_STR
                                                    references:references
                                                    newsgroups:newsgroups
                                                       subject:newSubject];
    
    // Chop off the hacky three CRs at the beginning of the text
    NSString *articleText = [textView.text substringFromIndex:3];
    
    // Strip-out instances of paragraph sign
    articleText = [articleText stringByReplacingOccurrencesOfString:PARAGRAPH_SIGN_STR
                                                         withString:EMPTY_STR];
    
    // Word-wrap the text at column 78
    articleText = [articleText stringByWrappingWordsAtColumn:78];

    NSData *articleData = [formatter articleDataWithHeaders:headers
                                                       text:articleText
                                               formatFlowed:YES];
    
//    // TESTING
//    const char *bytes = articleData.bytes;
//    NSUInteger length = articleData.length;
    
    NetworkNewsAppDelegate *appDelegate = (NetworkNewsAppDelegate *)[[UIApplication sharedApplication] delegate];
    currentTask = [[PostArticleTask alloc] initWithConnection:appDelegate.connection
                                                         data:articleData];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(articlePosted:)
               name:ArticlePostedNotification
             object:currentTask];
    [nc addObserver:self
           selector:@selector(articleNotPosted:)
               name:ArticleNotPostedNotification
             object:currentTask];
    [nc addObserver:self
           selector:@selector(articlePostError:)
               name:TaskErrorNotification
             object:currentTask];

    [currentTask start];
}

#pragma mark -
#pragma mark Notifications

- (void)articlePosted:(NSNotification *)notification
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:nil object:currentTask];

    [activityIndicatorView stopAnimating];

    [delegate newArticleViewController:self didSend:YES];

    // We've finished our task
    currentTask = nil;
}

- (void)articleNotPosted:(NSNotification *)notification
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:nil object:currentTask];
    
    [activityIndicatorView stopAnimating];
    sendButtonItem.enabled = YES;
    
    NSString *errorString = [NSString stringWithFormat:
                             @"Posting articles to the server \"%@\" is not allowed.",
                             currentTask.connection.hostName];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cannot Post"
                                                        message:errorString
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];

    // We've finished our task
    currentTask = nil;
}

- (void)articlePostError:(NSNotification *)notification
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:nil object:currentTask];

    [activityIndicatorView stopAnimating];
    sendButtonItem.enabled = YES;

    AlertViewFailedConnection(currentTask.connection.hostName);

    // We've finished our task
    currentTask = nil;
}

- (void)subjectDidChange:(NSNotification *)notification
{
    if (subjectTextField.text.length > 0)
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
    NSValue *value = [info objectForKey:UIKeyboardBoundsUserInfoKey];
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
    NSValue *value = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    CGSize keyboardSize = value.CGRectValue.size;
    
    // Reset the height of the scroll view to its original value
    CGRect frame = self.view.frame;
    frame.size.height += keyboardSize.height;
    self.view.frame = frame;
    
    keyboardShown = NO;
}

@end
