//
//  NetworkNewsTests.m
//  NetworkNewsTests
//
//  Created by David Schweinsberg on 17/02/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AppDelegate.h"
#import "NewsAccount.h"
#import "NewsConnectionPool.h"
#import "NewsConnection.h"
#import "NewsResponse.h"
#import "NNArticleFormatter.h"
#import "EncodedWordEncoder.h"

@interface NetworkNewsTests : XCTestCase
{
    NewsAccount *account;
    NewsConnectionPool *pool;
}

@end

@implementation NetworkNewsTests

- (void)setUp
{
    [super setUp];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSArray *accounts = appDelegate.accounts;
    account = accounts[0];
    pool = [[NewsConnectionPool alloc] initWithAccount:account];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testPostArticle
{
    NNArticleFormatter *formatter = [[NNArticleFormatter alloc] init];
    EncodedWordEncoder *encoder = [[EncodedWordEncoder alloc] init];

    // Use header entries with non-ASCII characters
    NSString *name = [encoder encodeString:@"Føø Bår"];
    NSString *email = @"test@example.com";
    NSString *emailAddress = [NSString stringWithFormat:@"%@ <%@>", name, email];
    NSString *newsgroups = @"misc.test";
    NSString *subject = [encoder encodeString:@"Tëst"];
    NSArray *headers = [NNArticleFormatter headerArrayWithDate:[NSDate date]
                                                          from:emailAddress
                                                       replyTo:nil
                                                  organization:nil
                                                     messageId:@""
                                                    references:nil
                                                    newsgroups:newsgroups
                                                       subject:subject];

    // Generate differing text so we don't get caught out with "duplicate message" errors
    NSString *text = [NSString stringWithFormat:@"Testing at %@", [[NSDate date] description]];
    NSData *articleData = [formatter articleDataWithHeaders:headers
                                                       text:text
                                               formatFlowed:YES];

    // Test that all characters are in the ASCII range
    const char *ptr = articleData.bytes;
    for (NSUInteger i = 0; i < articleData.length; ++i)
        XCTAssertLessThan(ptr[i], 127);

    // Post to the server and check the response status code
    NewsConnection *newsConnection = [pool dequeueConnection];
    NewsResponse *response = [newsConnection postData:articleData];
    if (response.statusCode == 240)
        NSLog(@"Article received: %@", response.string);
    else if (response.statusCode == 440)
        NSLog(@"Posting not permitted: %@", response.string);
    else if (response.statusCode == 441)
        NSLog(@"Posting failed: %@", response.string);
    [pool enqueueConnection:newsConnection];

    XCTAssertEqual(response.statusCode, 240, "Failed to post article");
}

- (void)testPostUTF8Article
{
    NNArticleFormatter *formatter = [[NNArticleFormatter alloc] init];
    EncodedWordEncoder *encoder = [[EncodedWordEncoder alloc] init];

    // Use header entries with non-ASCII characters
    NSString *name = [encoder encodeString:@"💁🏼‍♀️"];
    NSString *email = @"test@example.com";
    NSString *emailAddress = [NSString stringWithFormat:@"%@ <%@>", name, email];
    NSString *newsgroups = @"misc.test";
    NSString *subject = [encoder encodeString:@"☎️"];
    NSArray *headers = [NNArticleFormatter headerArrayWithDate:[NSDate date]
                                                          from:emailAddress
                                                       replyTo:nil
                                                  organization:nil
                                                     messageId:@""
                                                    references:nil
                                                    newsgroups:newsgroups
                                                       subject:subject];

    // Generate differing text so we don't get caught out with "duplicate message" errors
    NSString *text = [NSString stringWithFormat:@"📱 Testing at %@", [[NSDate date] description]];
    NSData *articleData = [formatter articleDataWithHeaders:headers
                                                       text:text
                                               formatFlowed:YES];

    // Post to the server and check the response status code
    NewsConnection *newsConnection = [pool dequeueConnection];
    NewsResponse *response = [newsConnection postData:articleData];
    if (response.statusCode == 240)
        NSLog(@"Article received: %@", response.string);
    else if (response.statusCode == 440)
        NSLog(@"Posting not permitted: %@", response.string);
    else if (response.statusCode == 441)
        NSLog(@"Posting failed: %@", response.string);
    [pool enqueueConnection:newsConnection];

    XCTAssertEqual(response.statusCode, 240, "Failed to post article");
}

@end
