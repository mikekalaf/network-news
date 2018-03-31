//
//  ArticleViewController.m
//  Network News
//
//  Created by David Schweinsberg on 27/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ArticleViewController.h"
#import "FetchArticleOperation.h"
#import "AppDelegate.h"
#import "Article.h"
#import "ArticlePart.h"
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
#import "CoreDataStore.h"
#import "NSString+NewsAdditions.h"
#import "EncodedWordDecoder.h"
#import "WelcomeViewController.h"
#import "NewsConnectionPool.h"
#import "NewsAccount.h"
#import "NSMutableAttributedString+NewsAdditions.h"
#import "ExtendedLayoutManager.h"
#import "NNNewsrc.h"

@interface ArticleViewController () <NewArticleDelegate, MFMailComposeViewControllerDelegate>
{
    UIProgressView *_progressView;
    Article *_article;
    NSOperationQueue *_operationQueue;
    NSURL *_cacheURL;
    NSURL *_attachmentURL;
    NSArray *_headEntries;
    NSData *_bodyTextDataTop;
    NSData *_bodyTextDataBottom;
    NSTextAttachment *_textAttachment;
}

@property(nonatomic) UITextView *textView;
@property(nonatomic, readonly, copy) NSString *bodyTextForFollowUp;

- (NSURL *)cacheURLForMessageId:(NSString *)messageId extension:(NSString *)extension;
- (void)followUpToGroup;
- (void)replyViaEmail;
- (NSString *)headerValueWithName:(NSString *)name;
- (void)updateWithPlaceholder;
- (void)loadArticle;
- (void)updateContent;
- (void)updateTitle;
- (void)updateNavigationControls;
- (void)disableNavigationControls;
- (void)showProgressToolbar;
- (void)showArticleToolbar;

- (IBAction)replyButtonPressed:(id)sender;

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

    // Add a text view with our own layout manager
    NSTextStorage *textStorage = [[NSTextStorage alloc] init];
    NSLayoutManager *layoutManager = [[ExtendedLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeZero];
    [layoutManager addTextContainer:textContainer];

    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds
                                        textContainer:textContainer];
    self.textView.editable = NO;
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.textView];

    NSDictionary *views = NSDictionaryOfVariableBindings(_textView);
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[_textView]|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:views];
    [self.view addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_textView]|"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self.view addConstraints:constraints];

    // Set up the operation queue to download one part at a time
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.maxConcurrentOperationCount = 1;
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button-down-arrow"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(nextArticlePressed:)];
    UIBarButtonItem *previousButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button-up-arrow"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(previousArticlePressed:)];
    self.navigationItem.rightBarButtonItems = @[nextButton, previousButton];

    [self updateTitle];
    [self disableNavigationControls];

    // Create a progress view to use with the toolbar
    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    _progressView.hidden = YES;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(fetchArticleCompleted:)
               name:FetchArticleCompletedNotification
             object:nil];

    [self updateArticle];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_operationQueue cancelAllOperations];

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

- (void)viewWillLayoutSubviews
{
    if (_textAttachment)
    {
        UIImage *image = _textAttachment.image;
        float maxWidth = self.view.bounds.size.width - 10;
        if (image.size.width > maxWidth)
        {
            int height = image.size.height * (maxWidth / image.size.width);
            _textAttachment.bounds = CGRectMake(0, 0, maxWidth, height);
        }
        else
        {
            _textAttachment.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
        }
    }
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)setGroupName:(NSString *)groupName
{
    _groupName = groupName;

    // Determine the cache directory, and make sure it exists
    if (_groupName)
    {
        //_cacheURL = [[[_connectionPool account] cacheURL] URLByAppendingPathComponent:_groupName];

        // Let's put all articles into the same directory, which will make it easier to
        // clean up plus any cross-postings will share the same cache
        _cacheURL = [_connectionPool.account.cacheURL URLByAppendingPathComponent:@"Articles"];

        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager createDirectoryAtURL:_cacheURL
              withIntermediateDirectories:YES
                               attributes:nil
                                    error:NULL];
    }
}

#pragma mark - Public Methods

- (void)updateArticle
{
    [self loadArticle];
}

#pragma mark - NewArticleDelegate Methods

- (void)newArticleViewController:(NewArticleViewController *)controller
                         didSend:(BOOL)send
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Actions

- (IBAction)nextArticlePressed:(id)sender
{
    if (_articleIndex < [_articleSource articleCount] - 1)
    {
        ++_articleIndex;
        [self loadArticle];
        [self updateTitle];
    }
}

- (IBAction)previousArticlePressed:(id)sender
{
    if (_articleIndex > 0)
    {
        --_articleIndex;
        [self loadArticle];
        [self updateTitle];
    }
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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Follow-up to group"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                [self followUpToGroup];
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reply via email"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                [self replyViaEmail];
                                            }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Notifications

//- (void)articleLoaded:(NSNotification *)notification
//{
//    // Do we have all parts?
//    NSUInteger completePartCount = [[_article completePartCount] integerValue];
//    if (completePartCount == 1 && _attachmentURL == nil)
//    {
//        // NOP
//    }
//    else if (completePartCount == partCount && _attachmentURL != nil)
//    {
//        // NOP
//    }
//    else
//    {
//        NSLog(@"Incomplete parts");
//    }
//
//    [self updateContent];
//    [_webView loadHTMLString:htmlString baseURL:nil];
//    [self updateNavigationControls];
//    [self showArticleToolbar];
//
//    // We've finished our task
//    currentTask = nil;
//
//    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//    [nc removeObserver:self];
//
//    // TODO: This notification is also being called by articleError: so we
//    // can't assume that the article has in fact been read. The above code, and
//    // all other code that updates and displays article HTML should be factored-out
//    // and called by these notifications, rather than having one notification
//    // calling another.
//
//    // Mark it as read, since we're loading it to be viewed
//    [_article setRead:[NSNumber numberWithBool:YES]];
//    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    [appDelegate.activeCoreDataStack save];
//}
//
//- (void)articleUnavailable:(NSNotification *)notification
//{
//    // Clear the body
////    [self beginHTML];
////    [self appendHeadFromArticle];
////
////    [htmlString appendString:@"<p class=\"status\">Article Unavailable</p>"];
////
////    [self endHTML];
////    [_webView loadHTMLString:htmlString baseURL:nil];
//    [self updateNavigationControls];
//    [self showArticleToolbar];
//
//    // We've finished our task
//    currentTask = nil;
//
//    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//    [nc removeObserver:self];
//}
//
//- (void)articleError:(NSNotification *)notification
//{
////    AlertViewFailedConnection(currentTask.connection.hostName);
//    [self articleLoaded:notification];
//}

- (void)fetchArticleCompleted:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSInteger statusCode = [userInfo[@"statusCode"] integerValue];
    if (statusCode == 220 || statusCode == 222)
    {
        if ([userInfo[@"partNumber"] integerValue] == [userInfo[@"totalPartCount"] integerValue])
        {
            // All parts have loaded
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loadArticle];
            });
        }
    }
    else
    {
        
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"NewArticle"])
    {
        // Collect the references, and add this messageId
        NSMutableString *references = [NSMutableString stringWithCapacity:1];
        if (_article.references)
        {
            [references appendString:_article.references];
            [references appendString:@" "];
        }
        [references appendString:_article.firstMessageId];

        // Make sure we follow-up to the requested group
        NSString *followupTo = [self headerValueWithName:@"Followup-To"];
        if (!followupTo)
            followupTo = _groupName;

        UINavigationController *navigationController = segue.destinationViewController;
        NewArticleViewController *viewController = (NewArticleViewController *)navigationController.topViewController;
        viewController.connectionPool = _connectionPool;
        viewController.delegate = self;
        viewController.groupName = followupTo;
        viewController.subject = _article.reSubject;
        viewController.references = references;
        viewController.messageBody = self.bodyTextForFollowUp;
    }
}

#pragma mark - Private Methods

- (NSURL *)cacheURLForMessageId:(NSString *)messageId extension:(NSString *)extension
{
    NSString *fileName = [messageId messageIDFileName];
    return [_cacheURL URLByAppendingPathComponent:[fileName stringByAppendingPathExtension:extension]];
}

- (NSString *)bodyTextForFollowUp
{
    // - Insert '>' quote markers at the head of each line
    // - Drop any signature
    NNQuoteLevelParser *qlp = [[NNQuoteLevelParser alloc] initWithData:_bodyTextDataTop
                                                                flowed:YES];
    NSArray *quoteLevels = qlp.quoteLevels;

    NSMutableString *mutableString = [NSMutableString stringWithCapacity:_bodyTextDataTop.length];
    
    [mutableString appendFormat:@"%@ wrote:\n", _article.from];
    
    for (NNQuoteLevel *quoteLevel in quoteLevels)
    {
        if (quoteLevel.signatureDivider)
            break;
        
        NSData *lineData = [_bodyTextDataTop subdataWithRange:quoteLevel.range];
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
    [self performSegueWithIdentifier:@"NewArticle" sender:self];
}

- (void)replyViaEmail
{
    if ([MFMailComposeViewController canSendMail] == NO)
    {
        return;
    }

    // Who do we reply to?
    NSString *replyTo = [self headerValueWithName:@"Reply-To"];
    if (!replyTo)
        replyTo = _article.from;
    
    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
    [mailViewController setToRecipients:@[replyTo]];
    [mailViewController setSubject:_article.reSubject];
    [mailViewController setMessageBody:[self bodyTextForFollowUp] isHTML:NO];
    mailViewController.mailComposeDelegate = self;
    [self presentViewController:mailViewController
                       animated:YES
                     completion:NULL];
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
        NSLog(@"Media Type: '%@'", contentType.mediaType);
        NSLog(@"Charset   : '%@'", contentType.charset);
        NSLog(@"Format    : '%@'", contentType.format);
        
        flowed = contentType.formatFlowed;
    }
    return flowed;
}

- (NSString *)charsetName
{
    NSString *charsetName = nil;
    ContentType *contentType = [self contentType];
    if (contentType)
        charsetName = contentType.charset;
    return charsetName;
}

- (NSStringEncoding)charsetEncoding
{
    CFStringEncoding encoding = kCFStringEncodingASCII;
    NSString *encodingName = [self charsetName];
    if (encodingName)
    {
        encoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)(encodingName));
        if (encoding == kCFStringEncodingInvalidId)
            encoding = kCFStringEncodingASCII;
    }
    return CFStringConvertEncodingToNSStringEncoding(encoding);
}

- (void)updateWithPlaceholder
{
    // No article has been selected, so put a placeholder here - this will
    // happen on the iPad when the article view is displayed with no
    // selected article
//    [self beginHTML];
//    [htmlString appendString:@"<p class=\"status\">No selected article</p>"];
//    [self endHTML];
//    [_webView loadHTMLString:htmlString baseURL:nil];
    [self updateNavigationControls];
}

- (void)updateContent
{
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];

    // Is the content format=flowed?
    BOOL flowed = [self isFlowed];

    // Append the text preceeding any attachment (might be all the text)
    [attrString appendNewsHead:_headEntries];
//    [attrString appendShortNewsHead:_headEntries];
    [attrString appendNewsBody:_bodyTextDataTop flowed:flowed];

    if (_attachmentURL)
    {
        // Append the attachment
        NSData *attachmentData = [[NSData alloc] initWithContentsOfURL:_attachmentURL];
        UIImage *image = [UIImage imageWithData:attachmentData];
        _textAttachment = [[NSTextAttachment alloc] init];
        _textAttachment.image = image;

        float maxWidth = _textView.bounds.size.width - 10;
        if (image.size.width > maxWidth)
        {
            int height = image.size.height * (maxWidth / image.size.width);
            _textAttachment.bounds = CGRectMake(0, 0, maxWidth, height);
        }

        [attrString appendAttributedString:
         [NSAttributedString attributedStringWithAttachment:_textAttachment]];
    }
    else
    {
        _textAttachment = nil;
    }

    // Append any text following the attachment
    [attrString appendNewsBody:_bodyTextDataBottom flowed:flowed];

    [self.textView.textStorage setAttributedString:attrString];

    _progressView.hidden = YES;
}

- (NSArray *)cachedURLsForMessageID:(NSString *)messageID
{
    // Get the contents of the cache directory and filter on the message ID
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *contents = [fileManager contentsOfDirectoryAtURL:_cacheURL
                                   includingPropertiesForKeys:nil
                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        error:&error];
    if (error)
        return nil;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"lastPathComponent CONTAINS %@",
                              [messageID messageIDFileName]];
    return [contents filteredArrayUsingPredicate:predicate];
}

- (void)loadArticle
{
    _attachmentURL = nil;
    _headEntries = nil;
    _bodyTextDataTop = nil;
    _bodyTextDataBottom = nil;

    // Reference the current article
    _article = [_articleSource articleAtIndex:_articleIndex];

    // TODO: Display some appropriate message
    if (_article == nil)
        return;
    
    // Clear the body
//    [self beginHTML];
//    [self appendHeadFromArticle];
    
//    SizeFormatter *formatter = [[SizeFormatter alloc] init];
//    NSString *sizeString = [formatter stringForObjectValue:[_article totalByteCount]];

//    if ([_article hasAllParts] == NO)
//    {
//        [htmlString appendString:@"<p class=\"status\">Incomplete parts</p>"];
//    }
//    else
//        [htmlString appendFormat:@"<p class=\"status\">Loading (%@)...</p>", sizeString];

//    [self endHTML];
//    [_webView loadHTMLString:htmlString baseURL:nil];

    // Bail out if the article has incomplete parts
    if (_article.hasAllParts == NO)
    {
        [self updateNavigationControls];
        return;
    }

    // We'll download the parts in the correct order, so we can choose to
    // save them into a single file.  Also, with uuencoding, only the first
    // part will have the required filename.
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"partNumber"
                                                               ascending:YES];
    NSArray *sortedParts = [_article.parts.allObjects sortedArrayUsingDescriptors:
                            @[descriptor]];

    NSString *messageID = [sortedParts[0] messageId];
    NSArray *URLs = [self cachedURLsForMessageID:messageID];
    if (URLs.count)
    {
        for (NSURL *cacheURL in URLs)
        {
            NSString *lastPathComponent = cacheURL.lastPathComponent;
            if ([lastPathComponent hasSuffix:@"0.txt"])
            {
                // Load the headers
                NSData *headData = [NSData dataWithContentsOfURL:cacheURL];
                if (headData)
                {
                    NNHeaderParser *hp = [[NNHeaderParser alloc] initWithData:headData];
                    _headEntries = hp.entries;
                }
            }
            else if ([lastPathComponent hasSuffix:@"1.txt"])
            {
                _bodyTextDataTop = [[NSData alloc] initWithContentsOfURL:cacheURL];
            }
            else if ([lastPathComponent hasSuffix:@"3.txt"])
            {
                _bodyTextDataBottom = [[NSData alloc] initWithContentsOfURL:cacheURL];
            }
            else
            {
                _attachmentURL = cacheURL;
            }
        }

        [_textView setContentOffset:CGPointZero animated:NO];

        // Display the cached copy
        [self updateContent];
        [self updateNavigationControls];
        [self showArticleToolbar];

        // Mark as read all the article parts that make this article
        for (ArticlePart *part in _article.parts)
        {
            [_connectionPool.account.newsrc setRead:YES
                                           forGroupName:_groupName
                                          articleNumber:part.articleNumber.integerValue];
        }
    }
    else
    {
        // Download from the server
        [self disableNavigationControls];
        [self showProgressToolbar];
        _progressView.progress = 0;
        _progressView.hidden = NO;
        
        NSLog(@"Downloading %lu part(s)", (unsigned long)sortedParts.count);

        // "Common info" carries the attachment filename from the first part
        // to all the following parts - it relies on the operations being done
        // sequentially and in order. See if this process can be improved.
        NSMutableDictionary *commonInfo = [[NSMutableDictionary alloc] initWithCapacity:1];
        NSUInteger totalBytes = _article.totalByteCount.integerValue;
        __block NSUInteger bytesFetchedSoFar = 0;

        for (ArticlePart *part in sortedParts)
        {
            FetchArticleOperation *operation =
            [[FetchArticleOperation alloc] initWithConnectionPool:_connectionPool
                                                        messageID:part.messageId
                                                       partNumber:part.partNumber.integerValue
                                                   totalPartCount:sortedParts.count
                                                         cacheURL:_cacheURL
                                                       commonInfo:commonInfo
                                                         progress:^(NSUInteger bytesReceived) {
                                                             bytesFetchedSoFar += bytesReceived;
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 self->_progressView.progress = (float)bytesFetchedSoFar / totalBytes;
                                                             });
                                                         }];
            [_operationQueue addOperation:operation];
        }
    }
}

- (void)updateTitle
{
    self.title = [NSString stringWithFormat:@"%ld of %lu",
                    (unsigned long)_articleIndex + 1,
                    (unsigned long)[_articleSource articleCount]];
}

- (void)updateNavigationControls
{
    // Enable/disable the navigation controls
    (self.navigationItem.rightBarButtonItems[0]).enabled = (_articleIndex < [_articleSource articleCount] - 1);
    (self.navigationItem.rightBarButtonItems[1]).enabled = (_articleIndex > 0);
}

- (void)disableNavigationControls
{
    // Enable/disable the navigation controls
    [self.navigationItem.rightBarButtonItems[0] setEnabled:NO];
    [self.navigationItem.rightBarButtonItems[1] setEnabled:NO];
}

- (void)showProgressToolbar
{
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
