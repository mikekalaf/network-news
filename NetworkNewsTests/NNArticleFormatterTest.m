//
//  NNArticleFormatterTest.m
//  NetworkNewsTests
//
//  Created by David Schweinsberg on 4/17/18.
//  Copyright © 2018 David Schweinsberg. All rights reserved.
//

#import "NNArticleFormatter.h"
#import "NNHeaderEntry.h"
#import "NSString+NewsAdditions.h"
#import <XCTest/XCTest.h>

@interface NNArticleFormatterTest : XCTestCase

@end

@implementation NNArticleFormatterTest

- (void)setUp {
  [super setUp];
  // Put setup code here. This method is called before the invocation of each
  // test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
  [super tearDown];
}

- (void)testHeaderFormatting {
  NSDate *date = [NSDate date];
  NSArray *headers =
      [NNArticleFormatter headerArrayWithDate:date
                                         from:@"test@test.com"
                                      replyTo:@"reply@test.com"
                                 organization:@"Testing Inc"
                                    messageId:@"<msg-tst-123>"
                                   references:@"<msg-ref-456> <msg-ref-789>"
                                   newsgroups:@"misc.test"
                                      subject:@"Unit testing"];
  NSUInteger count = 0;
  for (NNHeaderEntry *entry in headers) {
    if ([entry.name isEqualToString:@"Date"]) {
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      dateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z";
      XCTAssert(
          [entry.value isEqualToString:[dateFormatter stringFromDate:date]],
          "Expecting 'Date' value");
      ++count;
    } else if ([entry.name isEqualToString:@"From"]) {
      XCTAssert([entry.value isEqualToString:@"test@test.com"],
                "Expecting 'From' value");
      ++count;
    } else if ([entry.name isEqualToString:@"Newsgroups"]) {
      XCTAssert([entry.value isEqualToString:@"misc.test"],
                "Expecting 'Newsgroups' value");
      ++count;
    } else if ([entry.name isEqualToString:@"Subject"]) {
      XCTAssert([entry.value isEqualToString:@"Unit testing"],
                "Expecting 'Subject' value");
      ++count;
    } else if ([entry.name isEqualToString:@"References"]) {
      XCTAssert([entry.value isEqualToString:@"<msg-ref-456> <msg-ref-789>"],
                "Expecting 'References' value");
      ++count;
    } else if ([entry.name isEqualToString:@"Reply-To"]) {
      XCTAssert([entry.value isEqualToString:@"reply@test.com"],
                "Expecting 'Reply-To' value");
      ++count;
    } else if ([entry.name isEqualToString:@"Organization"]) {
      XCTAssert([entry.value isEqualToString:@"Testing Inc"],
                "Expecting 'Organization' value");
      ++count;
    } else if ([entry.name isEqualToString:@"User-Agent"]) {
      XCTAssert([entry.value hasPrefix:@"NetworkNews"],
                "Expecting 'User-Agent' value");
      ++count;
    }
  }
  XCTAssertEqual(count, 8, "Unexpected number of headers");
}

- (void)testArticleFormatting {
  NSDate *date = [NSDate date];
  NSArray *headers =
      [NNArticleFormatter headerArrayWithDate:date
                                         from:@"test@test.com"
                                      replyTo:@"reply@test.com"
                                 organization:@"Testing Inc"
                                    messageId:@"<msg-tst-123>"
                                   references:@"<msg-ref-456> <msg-ref-789>"
                                   newsgroups:@"misc.test"
                                      subject:@"Unit testing"];
  NSString *articleText =
      @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do "
      @"eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad "
      @"minim veniam, quis nostrud exercitation ullamco laboris nisi ut "
      @"aliquip ex ea commodo consequat. Duis aute irure dolor in "
      @"reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla "
      @"pariatur. Excepteur sint occaecat cupidatat non proident, sunt in "
      @"culpa qui officia deserunt mollit anim id est laborum.\n\nLorem ipsum "
      @"dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor "
      @"incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, "
      @"quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
      @"commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "
      @"velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint "
      @"occaecat cupidatat non proident, sunt in culpa qui officia deserunt "
      @"mollit anim id est laborum.\n\nLorem ipsum dolor sit amet, consectetur "
      @"adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore "
      @"magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation "
      @"ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute "
      @"irure dolor in reprehenderit in voluptate velit esse cillum dolore eu "
      @"fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, "
      @"sunt in culpa qui officia deserunt mollit anim id est laborum.";
  articleText = [articleText stringByWrappingUnquotedWordsAtColumn:78];
  //    NSData *articleData = [NNArticleFormatter articleDataWithHeaders:headers
  //                                                                text:articleText
  //                                                        formatFlowed:YES];
}

@end
