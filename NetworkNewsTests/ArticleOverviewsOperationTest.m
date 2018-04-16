//
//  ArticleOverviewsOperationTest.m
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

@interface ArticleOverviewsOperationTest : XCTestCase
{
    NewsConnectionPool *pool;
    GroupStore *groupStore;
    NSOperationQueue *operationQueue;
}

@end

@implementation ArticleOverviewsOperationTest

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
    operationQueue = [[NSOperationQueue alloc] init];
}

- (void)tearDown {
    [super tearDown];
    [pool closeAllConnections];
}

- (void)testFetchOverviews {
    ArticleOverviewsOperation *operation =
    [[ArticleOverviewsOperation alloc] initWithConnectionPool:pool
                                                   groupStore:groupStore
                                                         mode:ArticleOverviewsLatest
                                              maxArticleCount:100];
    [operationQueue addOperation:operation];
    [operationQueue waitUntilAllOperationsAreFinished];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Article"
                                              inManagedObjectContext:groupStore.managedObjectContext];
    fetchRequest.entity = entity;

    NSError *error;
    NSArray *articles = [groupStore.managedObjectContext executeFetchRequest:fetchRequest
                                                                       error:&error];
    XCTAssertEqual(articles.count, 100, "Fewer than requested number of articles in store");

    // Sort into decending date order
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date"
                                                                   ascending:NO];
    articles = [articles sortedArrayUsingDescriptors:@[sortDescriptor]];
}

@end
