//
//  ArticleViewController.h
//  Network News
//
//  Created by David Schweinsberg on 27/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "NewArticleViewController.h"
#import "WelcomeViewController.h"

@protocol ArticleSource;

@class Article;
@class Task;

@interface ArticleViewController : UIViewController <
    NewArticleDelegate,
    UIActionSheetDelegate,
    UIPopoverControllerDelegate,
    UISplitViewControllerDelegate,
    MFMailComposeViewControllerDelegate,
    UIWebViewDelegate
>
{
    UIPopoverController *popoverController;

    UISegmentedControl *navigationSegmentedControl;
    UIProgressView *progressView;

    Article *article;
    NSMutableString *htmlString;
    Task *currentTask;
    NSString *cacheDir;
    NSUInteger partCount;
//    NSString *attachmentFileName;
    NSString *attachmentPath;
    NSArray *headEntries;
    NSData *bodyTextDataTop;
    NSData *bodyTextDataBottom;
    NSUInteger bytesCached;
    BOOL restoreArticleComposer;
    BOOL restoreEmailView;
    BOOL toolbarSetForPortrait;
}

@property(nonatomic, retain) IBOutlet UIToolbar *toolbar;

@property(nonatomic, retain) IBOutlet UIWebView *webView;

@property(nonatomic, retain) IBOutlet UIBarButtonItem *replyButtonItem;

@property(nonatomic, retain) IBOutlet UIBarButtonItem *composeButtonItem;

@property(nonatomic, assign) id <ArticleSource> articleSource;

@property(nonatomic) NSInteger articleIndex;

@property(nonatomic, retain) NSString* groupName;

- (void)restoreLevelWithSelectionArray:(NSArray *)aSelectionArray;

- (void)updateArticle;

- (void)showWelcomeView;

- (IBAction)replyButtonPressed:(id)sender;

- (IBAction)composeButtonPressed:(id)sender;

@end


@protocol ArticleSource

- (NSUInteger)articleCount;

- (Article *)articleAtIndex:(NSUInteger)index;

@end
