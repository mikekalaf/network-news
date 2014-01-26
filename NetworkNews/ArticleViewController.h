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

@protocol ArticleSource;

@class Article;
@class NewsConnectionPool;

@interface ArticleViewController : UIViewController <
    NewArticleDelegate,
    UIActionSheetDelegate,
    UIPopoverControllerDelegate,
    UISplitViewControllerDelegate,
    MFMailComposeViewControllerDelegate
>

@property (nonatomic) NewsConnectionPool *connectionPool;

@property(nonatomic, weak) id <ArticleSource> articleSource;

@property(nonatomic) NSInteger articleIndex;

@property(nonatomic, weak) NSString *groupName;

- (void)updateArticle;

- (void)showWelcomeView;

@end


@protocol ArticleSource

- (NSUInteger)articleCount;
- (Article *)articleAtIndex:(NSUInteger)index;

@end
