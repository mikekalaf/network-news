//
//  ArticleViewController.h
//  Network News
//
//  Created by David Schweinsberg on 27/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NewArticleViewController.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <UIKit/UIKit.h>

@protocol ArticleSource;
@class Article;
@class NewsConnectionPool;

@interface ArticleViewController : UIViewController

@property(nonatomic) NewsConnectionPool *connectionPool;
@property(nonatomic, weak) id<ArticleSource> articleSource;
@property(nonatomic) NSInteger articleIndex;
@property(nonatomic, weak) NSString *groupName;

- (void)updateArticle;

@end

@protocol ArticleSource

@property(NS_NONATOMIC_IOSONLY, readonly) NSUInteger articleCount;
- (Article *)articleAtIndex:(NSUInteger)index;

@end
