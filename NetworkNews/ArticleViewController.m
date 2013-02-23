//
//  ArticleViewController.m
//  Network News
//
//  Created by David Schweinsberg on 27/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ArticleViewController.h"
#import "DownloadArticlesTask.h"
#import "AppDelegate.h"
#import "Article.h"
#import "ArticlePart.h"
#import "NNConnection.h"
#import "Task.h"
#import "Attachment.h"
#import "ArticlePartContent.h"
#import "NNHeaderParser.h"
#import "NNHeaderEntry.h"
#import "NNQuoteLevelParser.h"
#import "NNQuoteLevel.h"
#import "ThreadViewController.h"
#import "ThreadListViewController.h"
#import "EmailAddressFormatter.h"
#import "SizeFormatter.h"
#import "NetworkNews.h"
#import "QuotedPrintableDecoder.h"
#import "ContentType.h"
#import "CoreDataStack.h"
#import "NSString+NewsAdditions.h"
#import "EncodedWordDecoder.h"
#import "WelcomeViewController.h"

@interface ArticleViewController ()
{
    UIPopoverController *_popoverController;

    UISegmentedControl *_navigationSegmentedControl;
    UIProgressView *_progressView;

    Article *_article;
    NSMutableString *htmlString;
    Task *currentTask;
    NSString *cacheDir;
    NSUInteger partCount;
    NSString *attachmentPath;
    NSArray *_headEntries;
    NSData *bodyTextDataTop;
    NSData *bodyTextDataBottom;
    NSUInteger bytesCached;
    BOOL toolbarSetForPortrait;
}

@property(nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property(nonatomic, weak) IBOutlet UIWebView *webView;
@property(nonatomic, weak) IBOutlet UIBarButtonItem *replyButtonItem;
@property(nonatomic, weak) IBOutlet UIBarButtonItem *composeButtonItem;

- (NSString *)cachePathForMessageId:(NSString *)messageId
                          extension:(NSString *)extension;
- (NSString *)bodyTextForFollowUp;
- (void)followUpToGroup;
- (void)replyViaEmail;
- (NSString *)headerValueWithName:(NSString *)name;
- (void)beginHTML;
- (void)endHTML;
- (void)appendHeadFromArticle;
- (void)updateWithPlaceholder;
- (void)downloadArticle;
- (void)updateContent;
- (void)updateTitle;
- (void)updateNavigationControls;
- (void)disableNavigationControls;
- (void)showProgressToolbar;
- (void)showArticleToolbar;

- (IBAction)replyButtonPressed:(id)sender;
- (IBAction)composeButtonPressed:(id)sender;

@end

@implementation ArticleViewController

- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    htmlString = [NSMutableString string];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        // Navigation up and down buttons for the right-hand side
        NSArray *itemArray = [NSArray arrayWithObjects:
                              [UIImage imageNamed:@"icon-triangle-up.png"],
                              [UIImage imageNamed:@"icon-triangle-down.png"],
                              nil];
        _navigationSegmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
        [_navigationSegmentedControl setMomentary:YES];
        _navigationSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        [_navigationSegmentedControl setWidth:44 forSegmentAtIndex:0];
        [_navigationSegmentedControl setWidth:44 forSegmentAtIndex:1];
        [_navigationSegmentedControl addTarget:self
                                       action:@selector(articleNavigation:)
                             forControlEvents:UIControlEventValueChanged];
        
        UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:_navigationSegmentedControl];
        self.navigationItem.rightBarButtonItem = segmentBarItem;
    }
    
    [self updateTitle];
//    [self updateNavigationControls];
    [self disableNavigationControls];

    // Create a progress view to use with the toolbar
    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    _progressView.hidden = YES;

    // Determine the cache directory, and make sure it exists
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    cacheDir = [appDelegate.cacheRootDir stringByAppendingPathComponent:_groupName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:cacheDir
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:NULL];

    [self updateArticle];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Cancel any live task/connection
    if (currentTask)
    {
        [currentTask cancel];
        currentTask = nil;
    }

    // Which view are we going to?
    UIViewController *currentViewController = self.navigationController.topViewController;
    if ([currentViewController isKindOfClass:[ThreadViewController class]])
    {
        // Ensure the thread index is up-to-date
        ThreadViewController *threadViewController = (ThreadViewController *)currentViewController;
        
        // So the current article is within view on returning
        [threadViewController returningFromArticleIndex:_articleIndex];
    }
    else if ([currentViewController isKindOfClass:[ThreadListViewController class]])
    {
        // So the current article is within view on returning
        ThreadListViewController *threadListViewController = (ThreadListViewController *)currentViewController;
        [threadListViewController returningFromArticleIndex:_articleIndex];
    }
    
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark -
#pragma mark Public Methods

- (void)updateArticle
{
    if (_popoverController)
        [_popoverController dismissPopoverAnimated:YES];
    
//    if (articles)
        [self downloadArticle];
//    else
//        [self updateWithPlaceholder];
}

- (void)showWelcomeView
{
    WelcomeViewController *viewController = [[WelcomeViewController alloc] init];
//    viewController.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];

    [self.splitViewController presentViewController:navigationController animated:NO completion:NULL];
    //[self presentModalViewController:navigationController animated:NO];
}

#pragma mark -
#pragma mark NewArticleDelegate Methods

- (void)newArticleViewController:(NewArticleViewController *)controller
                         didSend:(BOOL)send
{
    [self dismissViewControllerAnimated:YES completion:NULL];

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate.savedLocation removeLastObject];
}

#pragma mark -
#pragma mark WelcomeDelegate Methods

- (void)welcomeViewControllerFinished:(WelcomeViewController *)controller
{
    NSLog(@"New user welcomed");
    
    [self dismissViewControllerAnimated:YES completion:NULL];

    // Establish a connection to the newly specified server
    // TODO: Rework how this happens on the iPad
//    NetworkNewsAppDelegate *appDelegate = (NetworkNewsAppDelegate *)[[UIApplication sharedApplication] delegate];
//    [appDelegate establishConnection];
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:NULL];

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate.savedLocation removeLastObject];
}

#pragma mark -
#pragma mark UIWebViewDelegate Methods

-            (BOOL)webView:(UIWebView *)aWebView
shouldStartLoadWithRequest:(NSURLRequest *)request
            navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        // If this is to the open internet, then open in an external browser
        if ([[[request URL] scheme] isEqualToString:@"http"] |
            [[[request URL] scheme] isEqualToString:@"https"])
        {
            [[UIApplication sharedApplication] openURL:[request URL]];
            return NO;
        }
    }
    return YES;
}

#pragma mark -
#pragma mark UIActionSheetDelegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        // Follow-up
        [self followUpToGroup];
    }
    else if (buttonIndex == 1)
    {
        // Email
        [self replyViaEmail];
    }
}

#pragma mark -
#pragma mark UISplitViewControllerDelegate Methods

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc
{
    barButtonItem.title = @"Articles";

    _popoverController = pc;

    if (toolbarSetForPortrait)
        return;

    // Navigation up and down buttons
    NSArray *itemArray = [NSArray arrayWithObjects:
                          [UIImage imageNamed:@"icon-triangle-up.png"],
                          [UIImage imageNamed:@"icon-triangle-down.png"],
                          nil];
    _navigationSegmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    _navigationSegmentedControl.tintColor = [UIColor colorWithWhite:0.66 alpha:1.0];
    [_navigationSegmentedControl setMomentary:YES];
    _navigationSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    [_navigationSegmentedControl setWidth:44 forSegmentAtIndex:0];
    [_navigationSegmentedControl setWidth:44 forSegmentAtIndex:1];
    [_navigationSegmentedControl addTarget:self
                                   action:@selector(articleNavigation:)
                         forControlEvents:UIControlEventValueChanged];
    
    UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:_navigationSegmentedControl];
    self.navigationItem.rightBarButtonItem = segmentBarItem;

    // Insert the split view controller's bar button item, and the navigation
    // segmented control, at the beginning of the toolbar
    NSMutableArray *items = [NSMutableArray arrayWithArray:_toolbar.items];
    [items insertObject:barButtonItem atIndex:0];
    [items insertObject:segmentBarItem atIndex:1];
    [_toolbar setItems:items animated:YES];
    
    toolbarSetForPortrait = YES;
}

- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Remove the split view controller's bar button item, and the navigation
    // segmented controller, from the toolbar
    NSMutableArray *items = [NSMutableArray arrayWithArray:_toolbar.items];
    [items removeObjectAtIndex:0];
    [items removeObjectAtIndex:0];
    [_toolbar setItems:items animated:YES];
    
    _popoverController = nil;

    toolbarSetForPortrait = NO;
}

#pragma mark -
#pragma mark Actions

- (void)articleNavigation:(id)sender
{
    NSUInteger index = _navigationSegmentedControl.selectedSegmentIndex;
    if (index == 0)
    {
        // Up Article
        if (_articleIndex > 0)
        {
            --_articleIndex;
            [self downloadArticle];
        }
    }
    else if (index == 1)
    {
        // Down Article
        if (_articleIndex < [_articleSource articleCount] - 1)
        {
            ++_articleIndex;
            [self downloadArticle];
        }
    }

    [self updateTitle];
    
    // TODO This needs to be fixed-up to record the thread
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.savedLocation removeLastObject];
    [appDelegate.savedLocation addObject:[NSNumber numberWithInteger:_articleIndex]];
}

- (IBAction)replyButtonPressed:(id)sender
{
    // Should any replies only go via email to the poster?
    NSString *followupTo = [self headerValueWithName:@"Followup-To"];
    if (followupTo && [followupTo caseInsensitiveCompare:@"poster"] == NSOrderedSame)
    {
        [self replyViaEmail];
        return;
    }

    // Show an action sheet to ask if this should be an email or a followup
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Follow-up to group", @"Reply via email", nil];
    if (_replyButtonItem)
        [actionSheet showFromBarButtonItem:_replyButtonItem animated:YES];
    else
        [actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (IBAction)composeButtonPressed:(id)sender
{
	// Save this level's selection to our AppDelegate
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate.savedLocation addObject:[NSNumber numberWithInteger:-2]];
    
    NewArticleViewController *viewController = [[NewArticleViewController alloc] initWithGroupName:_groupName
                                                                                           subject:nil
                                                                                        references:nil
                                                                                          bodyText:nil];
    viewController.delegate = self;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:navigationController animated:YES completion:NULL];
}

#pragma mark - Notifications

- (void)bytesLoaded:(NSNotification *)notification
{
    DownloadArticlesTask *task = notification.object;
    NSUInteger loadedBytes = task.articlePartContent.data.length;
    NSInteger totalBytes = [[_article totalByteCount] integerValue];
    _progressView.progress = (float)(bytesCached + loadedBytes) / totalBytes;
}

- (void)partLoaded:(NSNotification *)notification
{
    ++partCount;
    
    NSUInteger completePartCount = [[_article completePartCount] integerValue];
    
    DownloadArticlesTask *task = notification.object;
    NSUInteger partNumber = task.articlePart.partNumber.integerValue;

    if (partNumber == 1)
    {
        // This is the first part, so grab those headers
        _headEntries = [[task articlePartContent] headEntries];
    }

    NSString *contentTransferEncoding = [self headerValueWithName:@"Content-Transfer-Encoding"];

    Attachment *attachment = [[Attachment alloc] initWithContent:[task articlePartContent]
                                                     contentType:[self contentType]
                                         contentTransferEncoding:contentTransferEncoding];
    if (attachment)
    {
        if (partNumber != partCount)
        {
            NSLog(@"Expected part %d but received part %d", partCount, partNumber);
            return;
        }
        
        if (partNumber == 1)
        {
            // Grab the initial text in the first part
            // Calculate the range of the header text and the body text up to
            // the attachment
            NSRange range = NSMakeRange(0, attachment.rangeInArticleData.location);
            bodyTextDataTop = [task.articlePartContent.bodyData subdataWithRange:range];

            // Cache this initial text
            NSString *mIdHeadPath = [self cachePathForMessageId:task.articlePart.messageId
                                                      extension:@"head.txt"];
            ArticlePartContent *content = task.articlePartContent;
            NSData *headData = [content.data subdataWithRange:content.headRange];
            [headData writeToFile:mIdHeadPath atomically:NO];

            NSString *mIdPath = [self cachePathForMessageId:task.articlePart.messageId
                                                  extension:@"top.txt"];
            [bodyTextDataTop writeToFile:mIdPath atomically:NO];
            
            // Note the attachment filename
            attachmentPath = [self cachePathForMessageId:task.articlePart.messageId
                                               extension:attachment.fileName.pathExtension];
            [_article setAttachmentFileName:[attachment fileName]];

            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate.activeCoreDataStack save];
        }
        
        if (partNumber == completePartCount)
        {
            // Grab the trailing text in the last part (this could still be
            // the first part)

            NSUInteger end = NSMaxRange(attachment.rangeInArticleData);
            NSRange range = NSMakeRange(end,
                                        task.articlePartContent.bodyData.length - end);
            bodyTextDataBottom = [task.articlePartContent.bodyData subdataWithRange:range];

            // Cache this trailing text
            NSString *mIdPath = [self cachePathForMessageId:task.articlePart.messageId
                                                  extension:@"bottom.txt"];
            [bodyTextDataBottom writeToFile:mIdPath atomically:NO];
        }
        
        NSString *path = attachmentPath;
        if (partNumber == 1)
        {
            // Create the file
            NSError *error;
            if ([attachment.data writeToFile:path options:0 error:&error] == NO)
            {
                NSLog(@"Error in caching file: %@", error.description);
            }
            else
                bytesCached = task.articlePartContent.data.length;
        }
        else
        {
            // Append to the end of the file
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:attachment.data];
            [fileHandle closeFile];

            bytesCached += task.articlePartContent.data.length;
        }
    }
    else
    {
        // This is text only
        if (partNumber == 1)
        {
            BOOL quotedPrintable = [QuotedPrintableDecoder isQuotedPrintable:_headEntries];

            bodyTextDataTop = task.articlePartContent.bodyData;
            
            if (quotedPrintable)
            {
                QuotedPrintableDecoder *quotedPrintableDecoder = [[QuotedPrintableDecoder alloc] init];
                bodyTextDataTop = [quotedPrintableDecoder decodeData:bodyTextDataTop];
            }
            
            // Save to the cache
            NSString *mIdHeadPath = [self cachePathForMessageId:task.articlePart.messageId
                                                      extension:@"head.txt"];
            ArticlePartContent *content = task.articlePartContent;
            NSData *headData = [content.data subdataWithRange:content.headRange];
            [headData writeToFile:mIdHeadPath atomically:NO];

            NSString *mIdPath = [self cachePathForMessageId:task.articlePart.messageId
                                                  extension:@"top.txt"];
            [bodyTextDataTop writeToFile:mIdPath atomically:NO];
            
            NSLog(@"cache path: %@", mIdPath);
        }
    }
}

- (void)articleLoaded:(NSNotification *)notification
{
    // Do we have all parts?
    NSUInteger completePartCount = [[_article completePartCount] integerValue];
//    if (completePartCount == 1 && attachmentFileName == nil)
    if (completePartCount == 1 && attachmentPath == nil)
    {
        // NOP
    }
//    else if (completePartCount == partCount && attachmentFileName != nil)
    else if (completePartCount == partCount && attachmentPath != nil)
    {
        // NOP
    }
    else
    {
        NSLog(@"Incomplete parts");
    }
    
    [self updateContent];
    [_webView loadHTMLString:htmlString baseURL:nil];
    [self updateNavigationControls];
    [self showArticleToolbar];

    // We've finished our task
    currentTask = nil;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];

    // Mark it as read, since we're loading it to be viewed
    [_article setRead:[NSNumber numberWithBool:YES]];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.activeCoreDataStack save];
}

- (void)articleUnavailable:(NSNotification *)notification
{
    // Clear the body
    [self beginHTML];
    [self appendHeadFromArticle];
    
    [htmlString appendString:@"<p class=\"status\">Article Unavailable</p>"];
    
    [self endHTML];
    [_webView loadHTMLString:htmlString baseURL:nil];
    [self updateNavigationControls];
    [self showArticleToolbar];

    // We've finished our task
    currentTask = nil;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

- (void)articleError:(NSNotification *)notification
{
    AlertViewFailedConnection(currentTask.connection.hostName);
    [self articleLoaded:notification];
}

#pragma mark -
#pragma mark Private Methods

- (NSString *)cachePathForMessageId:(NSString *)messageId
                          extension:(NSString *)extension
{
    NSString *fileName = [messageId messageIDFileName];
    return [cacheDir stringByAppendingPathComponent:
            [fileName stringByAppendingPathExtension:extension]];
}

- (NSString *)bodyTextForFollowUp
{
    // - Insert '>' quote markers at the head of each line
    // - Drop any signature
    NNQuoteLevelParser *qlp = [[NNQuoteLevelParser alloc] initWithData:bodyTextDataTop
                                                                flowed:YES];
    NSArray *quoteLevels = qlp.quoteLevels;

    NSMutableString *mutableString = [NSMutableString stringWithCapacity:bodyTextDataTop.length];
    
    [mutableString appendFormat:@"%@ wrote:\n", [_article from]];
    
    for (NNQuoteLevel *quoteLevel in quoteLevels)
    {
        if (quoteLevel.signatureDivider)
            break;
        
        NSData *lineData = [bodyTextDataTop subdataWithRange:quoteLevel.range];
        NSString *str = [[NSString alloc] initWithData:lineData
                                              encoding:NSUTF8StringEncoding];
        if (!str)
            str = [[NSString alloc] initWithData:lineData
                                        encoding:NSISOLatin1StringEncoding];
        if (str)
        {
            NSString *level = [@"" stringByPaddingToLength:quoteLevel.level + 1
                                                withString:@">"
                                           startingAtIndex:0];
            [mutableString appendFormat:@"%@ %@", level, str];
        }
    }
    return mutableString;
}

- (void)followUpToGroup
{
	// Save this level's selection to our AppDelegate
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate.savedLocation addObject:[NSNumber numberWithInteger:-2]];

    // Collect the references, and add this messageId
    NSMutableString *references = [NSMutableString stringWithCapacity:1];
    if ([_article references])
    {
        [references appendString:[_article references]];
        [references appendString:@" "];
    }
    [references appendString:[_article firstMessageId]];
    
    // Make sure we follow-up to the requested group
    NSString *followupTo = [self headerValueWithName:@"Followup-To"];
    if (!followupTo)
        followupTo = _groupName;
    
    NewArticleViewController *viewController = [[NewArticleViewController alloc] initWithGroupName:followupTo
                                                                                           subject:[_article reSubject]
                                                                                        references:references
                                                                                          bodyText:[self bodyTextForFollowUp]];
    viewController.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];

    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:navigationController animated:YES completion:NULL];
}

- (void)replyViaEmail
{
    if ([MFMailComposeViewController canSendMail] == NO)
    {
        return;
    }

	// Save this level's selection to our AppDelegate
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate.savedLocation addObject:[NSNumber numberWithInteger:-3]];
    
    // Who do we reply to?
    NSString *replyTo = [self headerValueWithName:@"Reply-To"];
    if (!replyTo)
        replyTo = [_article from];
    
    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
    [mailViewController setToRecipients:[NSArray arrayWithObject:replyTo]];
    [mailViewController setSubject:[_article reSubject]];
    [mailViewController setMessageBody:[self bodyTextForFollowUp] isHTML:NO];
    mailViewController.mailComposeDelegate = self;
    [self presentViewController:mailViewController
                       animated:YES
                     completion:NULL];
}

- (NSData *)htmlEscapedData:(NSData *)unescapedData
{
    const char *amp = "&amp;";
    const char *lt = "&lt;";
    const char *gt = "&gt;";
    const char *quot = "&quot;";
    const char *single_quot = "&#039;";
    
    NSMutableData *escapedData = [NSMutableData dataWithCapacity:unescapedData.length];
    
    const char *bytes = unescapedData.bytes;
    NSUInteger len = unescapedData.length;
    for (NSUInteger i = 0; i < len; ++i)
    {
        switch (bytes[i])
        {
            case '&':
                [escapedData appendBytes:amp length:5];
                break;
            case '<':
                [escapedData appendBytes:lt length:4];
                break;
            case '>':
                [escapedData appendBytes:gt length:4];
                break;
            case '"':
                [escapedData appendBytes:quot length:6];
                break;
            case '\'':
                [escapedData appendBytes:single_quot length:6];
                break;
            default:
                [escapedData appendBytes:bytes + i length:1];
        }
    }
    
    return escapedData;
}

- (NSString *)htmlEscapedString:(NSString *)unescapedString
{
    NSData *unescapedData = [unescapedString dataUsingEncoding:NSUTF8StringEncoding
                                          allowLossyConversion:NO];
//    if (unescapedData == nil)
//        unescapedData = [unescapedString dataUsingEncoding:NSISOLatin1StringEncoding
//                                      allowLossyConversion:YES];
    if (unescapedData == nil)
    {
        NSLog(@"Failed to encode '%@' as UTF-8", unescapedString);
        return nil;
    }
    
    NSData *escapedData = [self htmlEscapedData:unescapedData];
    return [[NSString alloc] initWithData:escapedData encoding:NSUTF8StringEncoding];
}

- (NSString *)headerValueWithName:(NSString *)name
{
    for (NNHeaderEntry *entry in _headEntries)
        if ([entry.name caseInsensitiveCompare:name] == NSOrderedSame)
            return entry.value;
    return nil;
}

- (ContentType *)contentType
{
    ContentType *contentType = nil;
    NSString *contentTypeValue = [self headerValueWithName:@"Content-Type"];
    if (contentTypeValue)
        contentType = [[ContentType alloc] initWithString:contentTypeValue];
    return contentType;
}

- (BOOL)isFlowed
{
    BOOL flowed = NO;
    ContentType *contentType = [self contentType];
    if (contentType)
    {
        NSLog(@"Media Type: '%@'", [contentType mediaType]);
        NSLog(@"Charset   : '%@'", [contentType charset]);
        NSLog(@"Format    : '%@'", [contentType format]);
        
        flowed = [contentType isFormatFlowed];
    }
    return flowed;
}

- (NSString *)charsetName
{
    NSString *charsetName = nil;
    ContentType *contentType = [self contentType];
    if (contentType)
        charsetName = [contentType charset];
    return charsetName;
}

- (CFStringEncoding)charsetEncoding
{
    CFStringEncoding encoding = [EncodedWordDecoder charsetEncodingFromName:[self charsetName]];
    if (encoding == kCFStringEncodingInvalidId)
        encoding = kCFStringEncodingASCII;
    return encoding;
}

- (void)appendHeadFromArticle
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterLongStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    EmailAddressFormatter *emailFormatter = [[EmailAddressFormatter alloc] init];

    [htmlString appendFormat:
     @"<div class=\"field-block\">"
     @"<p class=\"field\"><span class=\"name\">From:</span> %@</p>"
     @"</div>"
     @"<div class=\"field-block\">"
     @"<p class=\"field subject\">%@</p>"
     @"<p class=\"field date\">%@</p>"
     @"</div>",
     [self htmlEscapedString:[emailFormatter stringForObjectValue:[_article from]]],
     [self htmlEscapedString:[_article subject]],
     [dateFormatter stringFromDate:[_article date]]];
}

- (void)beginQuoteLevel:(NSUInteger)level
{
    // Apply <div>s corresponding to the quote level
    for (NSUInteger i = 0; i <= level; ++i)
    {
        NSUInteger j = i;
        if (j > 3)
            j = (j - 1) % 3 + 1;
        [htmlString appendFormat:@"<div class=\"l%d\">", j];
    }
}

- (void)endQuoteLevel:(NSUInteger)level
{
    for (NSUInteger i = 0; i <= level; ++i)
        [htmlString appendString:@"</div>"];
}

- (void)beginSignature
{
    [htmlString appendString:@"<div class=\"sig\">"];
}

- (void)endSignature
{
    [htmlString appendString:@"</div>"];
}

- (void)appendBodyLineData:(NSData *)lineData encoding:(CFStringEncoding)encoding
{
    if (lineData.length == 2)
    {
        // Is this just a hard line break?
        if (memcmp(lineData.bytes, "\r\n", 2) == 0)
        {
            [htmlString appendString:@"<br/>"];
            return;
        }
    }

    // TODO: Keep an eye on this -- should we do the HTML escaping *after*
    // the decoding of the string?
    
    lineData = [self htmlEscapedData:lineData];

    // Decode used the specified encoding.  If this fails, try our two
    // fall-back encodings: UTF8 and ISOLatin1.
    CFStringRef strRef = CFStringCreateWithBytes(kCFAllocatorDefault,
                                                 lineData.bytes,
                                                 lineData.length,
                                                 encoding,
                                                 false);
    if (strRef == NULL)
    {
        strRef = CFStringCreateWithBytes(kCFAllocatorDefault,
                                         lineData.bytes,
                                         lineData.length,
                                         kCFStringEncodingUTF8,
                                         false);
    }

    if (strRef == NULL)
    {
        strRef = CFStringCreateWithBytes(kCFAllocatorDefault,
                                         lineData.bytes,
                                         lineData.length,
                                         kCFStringEncodingISOLatin1,
                                         false);
    }
    
    if (strRef)
    {
        [htmlString appendString:(__bridge NSString *)strRef];
        CFRelease(strRef);
    }
    
//    NSString *articleString = [[NSString alloc] initWithData:lineData
//                                                    encoding:NSUTF8StringEncoding];
//    if (!articleString)
//        articleString = [[NSString alloc] initWithData:lineData
//                                              encoding:NSISOLatin1StringEncoding];
//
//    [htmlString appendString:articleString];
//    [articleString release];
}

- (void)appendBodyData:(NSData *)bodyData
              encoding:(CFStringEncoding)encoding
                flowed:(BOOL)flowed
{
    // TODO: The "quote level parser" needs to be renamed since its role has
    // expanded with the support of format=flowed text and styling of sigs
    NNQuoteLevelParser *qlp = [[NNQuoteLevelParser alloc] initWithData:bodyData
                                                                flowed:flowed];
    NSArray *quoteLevels = qlp.quoteLevels;

    BOOL previousFlowed = NO;
    NSUInteger previousLevel = 0;
    BOOL inSignature = NO;
    
    [htmlString appendString:@"<p>"];
    for (NNQuoteLevel *quoteLevel in quoteLevels)
    {
        if (inSignature == NO && quoteLevel.signatureDivider)
        {
            [self beginSignature];
            inSignature = YES;
        }

        if (previousLevel != quoteLevel.level && previousFlowed == YES)
        {
            // The quote level has changed, even though the text was flowed
            [self endQuoteLevel:quoteLevel.level];
            previousFlowed = NO;
        }
        
        if (previousFlowed == NO)
            [self beginQuoteLevel:quoteLevel.level];
        
        NSData *lineData = [bodyData subdataWithRange:quoteLevel.range];
        [self appendBodyLineData:lineData encoding:encoding];
        
        if (quoteLevel.flowed == NO)
        {
            [self endQuoteLevel:quoteLevel.level];
            previousFlowed = NO;
        }
        else
        {
            previousFlowed = YES;
        }
    }
    if (inSignature)
        [self endSignature];

    [htmlString appendString:@"</p>"];
}

- (void)appendImageURL:(NSURL *)imageURL
{
    [htmlString appendFormat:@"<img src=\"%@\"/>", imageURL];
}

- (void)appendAudioURL:(NSURL *)audioURL
{
    [htmlString appendFormat:@"<audio src=\"%@\" controls=\"controls\">Some audio</audio>", audioURL];
}

- (void)appendLinkURL:(NSURL *)url
{
    [htmlString appendFormat:@"<a href=\"%@\">%@</a>", url, url];
}

- (void)beginHTML
{
    NSRange range = NSMakeRange(0, [htmlString length]);
    [htmlString deleteCharactersInRange:range];
    
    [htmlString appendString:@"<html>"
     "<head>"
     "<style>"
     "body { margin-top: 0; font-family: sans-serif }"
     "table { border-bottom-style: solid; border-bottom-width: 1; border-bottom-color: gray }"
     ".field-block { padding-top: 8px; padding-bottom: 8px; margin-left: -8px; margin-right: -8px; border-bottom: solid; border-width: thin; border-color: silver }"
     ".field { margin-top: 0; margin-left: 8px; margin-bottom: 0; margin-right: 8px }"
     ".name { margin-top: 0; color: gray; text-align: right }"
     ".subject { font-weight: bold }"
     ".date { color: gray }"
     ".sig { color: gray }"
     ".status { color: gray }"
     ".l1 { padding-left: 5pt; border-left-style: solid; border-left-color: blue; color: blue }"
     ".l2 { padding-left: 5pt; border-left-style: solid; border-left-color: green; color: green }"
     ".l3 { padding-left: 5pt; border-left-style: solid; border-left-color: red; color: red }"
     "img { width: 100% }"
     "object { width: 100% }"
     "</style>"
     "</head>"
     "<body>"];
}

- (void)endHTML
{
    [htmlString appendString:@"</body></html>"];
}

- (void)updateWithPlaceholder
{
    // No article has been selected, so put a placeholder here - this will
    // happen on the iPad when the article view is displayed with no
    // selected article
    [self beginHTML];
    [htmlString appendString:@"<p class=\"status\">No selected article</p>"];
    [self endHTML];
    [_webView loadHTMLString:htmlString baseURL:nil];
    [self updateNavigationControls];
}

- (void)updateContent
{
    [self beginHTML];
    
    // Is the content format=flowed?
    BOOL flowed = [self isFlowed];
    
    CFStringEncoding encoding = [self charsetEncoding];

    // Append the visible headers
    [self appendHeadFromArticle];

    // If there is an attachment, include it in the HTML, otherwise just
    // present the text
    // Append the text preceeding any attachment
    [self appendBodyData:bodyTextDataTop encoding:encoding flowed:flowed];

    if (attachmentPath)
    {
        // Append the attachment
        NSString *path = attachmentPath;
        NSURL *attachmentURL = [NSURL fileURLWithPath:path isDirectory:NO];
        
        if ([attachmentPath.pathExtension caseInsensitiveCompare:@"jpg"] == NSOrderedSame)
            [self appendImageURL:attachmentURL];
        else if ([attachmentPath.pathExtension caseInsensitiveCompare:@"mp3"] == NSOrderedSame)
            [self appendAudioURL:attachmentURL];
        else
            [self appendLinkURL:attachmentURL];
        
        // Append the text following the attachment
        [self appendBodyData:bodyTextDataBottom encoding:encoding flowed:flowed];
    }
    
    [self endHTML];
    
    _progressView.hidden = YES;
}

- (void)downloadArticle
{
    partCount = 0;
    attachmentPath = nil;
    _headEntries = nil;
    bodyTextDataTop = nil;
    bodyTextDataBottom = nil;
    bytesCached = 0;

    // Reference the current article
    _article = [_articleSource articleAtIndex:_articleIndex];
    
//    // Mark it as read, since we're loading it to be viewed
//    // TODO: Mark the article as read AFTER it is loaded, not before
//    article.read = [NSNumber numberWithBool:YES];

//    NetworkNewsAppDelegate *appDelegate = (NetworkNewsAppDelegate *)[[UIApplication sharedApplication] delegate];
//    [appDelegate.activeCoreDataStack save];
    
    // Clear the body
    [self beginHTML];
    [self appendHeadFromArticle];
    
    SizeFormatter *formatter = [[SizeFormatter alloc] init];
    NSString *sizeString = [formatter stringForObjectValue:[_article totalByteCount]];

    if ([_article hasAllParts] == NO)
    {
        [htmlString appendString:@"<p class=\"status\">Incomplete parts</p>"];
    }
    else
        [htmlString appendFormat:@"<p class=\"status\">Loading (%@)...</p>", sizeString];
    
    [self endHTML];
    [_webView loadHTMLString:htmlString baseURL:nil];

    // Bail out if the article has incomplete parts
    if ([_article hasAllParts] == NO)
    {
        [self updateNavigationControls];
        return;
    }

    // We'll download the parts in the correct order, so we can choose to
    // save them into a single file.  Also, with uuencoding, only the first
    // part will have the required filename.
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"partNumber"
                                                               ascending:YES];
    NSArray *sortedParts = [[[_article parts] allObjects] sortedArrayUsingDescriptors:
                            [NSArray arrayWithObject:descriptor]];

    // First, check if we have a cached copy?
    NSString *messageId = [[sortedParts objectAtIndex:0] messageId];
    NSString *mIdPath = [self cachePathForMessageId:messageId extension:@"top.txt"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:mIdPath])
    {
        NSLog(@"Found cached copy");
        
        bodyTextDataTop = [[NSData alloc] initWithContentsOfFile:mIdPath];
        
        // Load the headers
        mIdPath = [self cachePathForMessageId:messageId
                                    extension:@"head.txt"];
        NSData *headData = [NSData dataWithContentsOfFile:mIdPath];
        if (headData)
        {
            NNHeaderParser *hp = [[NNHeaderParser alloc] initWithData:headData];
            _headEntries = [hp entries];
        }
        
        // Is there an attachment to load?
        NSString *attachmentFileName = [_article attachmentFileName];
        if (attachmentFileName)
        {
            // Retrieve the cached attachment
            attachmentPath = [self cachePathForMessageId:messageId
                                               extension:attachmentFileName.pathExtension];
        }
        
        // Is there following text?
        mIdPath = [self cachePathForMessageId:messageId extension:@"bottom.txt"];
        if ([fileManager fileExistsAtPath:mIdPath])
            bodyTextDataBottom = [[NSData alloc] initWithContentsOfFile:mIdPath];

        // Display the cached copy
        [self updateContent];
        [_webView loadHTMLString:htmlString baseURL:nil];
        [self updateNavigationControls];
        [self showArticleToolbar];

        // Mark it as read
        [_article setRead:[NSNumber numberWithBool:YES]];
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate.activeCoreDataStack save];

        return;
    }
    
    // Proceed with the download
    [self disableNavigationControls];
    [self showProgressToolbar];
    _progressView.progress = 0;
    _progressView.hidden = NO;
    
    // Download the article(s)
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    currentTask = [[DownloadArticlesTask alloc] initWithConnection:appDelegate.connection
                                                      articleParts:sortedParts];
    
    NSLog(@"Downloading %d part(s)", sortedParts.count);
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(bytesLoaded:)
               name:ArticleBytesReceivedNotification
             object:currentTask];
    [nc addObserver:self
           selector:@selector(partLoaded:)
               name:ArticleDownloadedNotification
             object:currentTask];
    [nc addObserver:self
           selector:@selector(articleLoaded:)
               name:AllArticlesDownloadedNotification
             object:currentTask];
    [nc addObserver:self
           selector:@selector(articleUnavailable:)
               name:ArticleUnavailableNotification
             object:currentTask];
    [nc addObserver:self
           selector:@selector(articleError:)
               name:TaskErrorNotification
             object:currentTask];
    
    [currentTask start];
}

- (void)updateTitle
{
    [self setTitle:[NSString stringWithFormat:@"%d of %d",
                    _articleIndex + 1,
                    [_articleSource articleCount]]];
}

- (void)updateNavigationControls
{
    // Enable/disable the navigation controls
    [_navigationSegmentedControl setEnabled:(_articleIndex > 0)
                         forSegmentAtIndex:0];
    [_navigationSegmentedControl setEnabled:(_articleIndex < [_articleSource articleCount] - 1)
                         forSegmentAtIndex:1];
}

- (void)disableNavigationControls
{
    // Enable/disable the navigation controls
    [_navigationSegmentedControl setEnabled:NO forSegmentAtIndex:0];
    [_navigationSegmentedControl setEnabled:NO forSegmentAtIndex:1];
}

- (void)showProgressToolbar
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return;

    // Set up iPhone toolbar
    UIBarButtonItem *flexibleSpaceButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                  target:nil
                                                  action:nil];
    
    UIBarButtonItem *progressItem = [[UIBarButtonItem alloc] initWithCustomView:_progressView];
    
    self.toolbarItems = [NSArray arrayWithObjects:
                         flexibleSpaceButtonItem,
                         progressItem,
                         flexibleSpaceButtonItem,
                         nil];
}

- (void)showArticleToolbar
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return;

    // Set up iPhone toolbar
    UIBarButtonItem *flexibleSpaceButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                  target:nil
                                                  action:nil];
    
    UIBarButtonItem *aReplyButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply
                                                  target:self
                                                  action:@selector(replyButtonPressed:)];
    
    self.toolbarItems = [NSArray arrayWithObjects:
                         flexibleSpaceButtonItem,
                         aReplyButtonItem,
                         nil];
}

@end
