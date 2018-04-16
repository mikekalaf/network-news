//
//  FetchArticleOperationTest.m
//  NetworkNewsTests
//
//  Created by David Schweinsberg on 4/16/18.
//  Copyright © 2018 David Schweinsberg. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AppDelegate.h"
#import "NewsAccount.h"
#import "NewsConnectionPool.h"
#import "NewsConnection.h"
#import "NewsResponse.h"
#import "GroupStore.h"
#import "ArticleOverviewsOperation.h"
#import "FetchArticleOperation.h"
#import "Article.h"
#import "ArticlePart.h"

@interface FetchArticleOperationTest : XCTestCase
{
    NewsConnectionPool *pool;
    GroupStore *groupStore;
}

@end

@implementation FetchArticleOperationTest

- (void)setUp {
    [super setUp];

    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSArray *accounts = appDelegate.accounts;
    NewsAccount *account = accounts[0];
    pool = [[NewsConnectionPool alloc] initWithAccount:account];
    groupStore = [[GroupStore alloc] initWithStoreName:@"misc.test"
                                           inDirectory:@"test"
                        withPersistentStoreCoordinator:nil
                                          isMainThread:NO];
}

- (void)tearDown {
    [super tearDown];
    [pool closeAllConnections];
}

- (void)testFetchArticle {
    ArticleOverviewsOperation *operation =
    [[ArticleOverviewsOperation alloc] initWithConnectionPool:pool
                                                   groupStore:groupStore
                                                         mode:ArticleOverviewsLatest
                                              maxArticleCount:1];
    [operation start];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Article"
                                              inManagedObjectContext:groupStore.managedObjectContext];
    fetchRequest.entity = entity;

    NSError *error;
    NSArray *articles = [groupStore.managedObjectContext executeFetchRequest:fetchRequest
                                                                       error:&error];
    XCTAssertEqual(articles.count, 1, "Fewer than requested number of articles in store");

    Article *article = articles[0];
    ArticlePart *part = article.parts.anyObject;
    FetchArticleOperation *fao = [[FetchArticleOperation alloc] initWithConnectionPool:pool
                                                                             messageID:part.messageId
                                                                            partNumber:1
                                                                        totalPartCount:1
                                                                              cacheURL:pool.account.cacheURL
                                                                            commonInfo:nil
                                                                              progress:nil];
    NSNotificationCenter * __weak nc = [NSNotificationCenter defaultCenter];
    id __block token = [nc addObserverForName:FetchArticleCompletedNotification
                                       object:nil
                                        queue:[NSOperationQueue mainQueue]
                                   usingBlock:^(NSNotification *note) {
                                       NSDictionary *userInfo = note.userInfo;
                                       NSInteger statusCode = [userInfo[@"statusCode"] integerValue];
                                       if (statusCode == 220 || statusCode == 222)
                                       {
                                           NSLog(@"Article loaded!");
                                       }
                                       NSLog(@"Received the notification!");
                                       [nc removeObserver:token];
                                   }];
    [fao start];
}

@end
