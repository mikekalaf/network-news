//
//  NNHeaderParserTest.m
//  NetworkNewsTests
//
//  Created by David Schweinsberg on 4/17/18.
//  Copyright © 2018 David Schweinsberg. All rights reserved.
//

#import "NNHeaderParser.h"
#import "NNHeaderEntry.h"
#import <XCTest/XCTest.h>

@interface NNHeaderParserTest : XCTestCase

@end

@implementation NNHeaderParserTest

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

- (void)testUnfolding {
  NSString *article =
      @"220 status line (should this be here?)\r\n"
      @"Heading-1: First Line\r\n Second Line\r\n Third Line\r\n"
      @"Heading-2: One Line\r\n"
      @"\r\n"
      @"Body\r\n";
  NSData *articleData = [article dataUsingEncoding:NSUTF8StringEncoding];
  NNHeaderParser *parser = [[NNHeaderParser alloc] initWithData:articleData];
  XCTAssertEqual(parser.entries.count, 2, "Unexpected number of headers");

  NNHeaderEntry *entry = parser.entries[0];
  XCTAssert([entry.name isEqualToString:@"Heading-1"],
            "Unexpected header 1 name");
  XCTAssert([entry.value isEqualToString:@"First Line Second Line Third Line"],
            "Unexpected header 1 value");

  entry = parser.entries[1];
  XCTAssert([entry.name isEqualToString:@"Heading-2"],
            "Unexpected header 2 name");
  XCTAssert([entry.value isEqualToString:@"One Line"],
            "Unexpected header 2 value");
}

- (void)testHeaderParsing {

  NSString *article =
      @"220 status line (should this be here?)\r\n"
      @"X-Received: by 10.55.39.202 with SMTP id "
      @"n193mr7407498qkn.14.1522724473069;\r\n"
      @" Mon, 02 Apr 2018 20:01:13 -0700 (PDT)\r\n"
      @"X-Received: by 10.31.69.207 with SMTP id "
      @"s198mr1469776vka.0.1522724472888;\r\n"
      @" Mon, 02 Apr 2018 20:01:12 -0700 (PDT)\r\n"
      @"Path: "
      @"eternal-september.org!reader02.eternal-september.org!feeder.eternal-"
      @"september.org!paganini.bofh.team!weretis.net!feeder6.news.weretis.net!"
      @"feeder.usenetexpress.com!feeder-in1.iad1.usenetexpress.com!border1."
      @"nntp.dca1.giganews.com!nntp.giganews.com!k3no133715qtm.1!news-out."
      @"google.com!c39ni1306qta.0!nntp.google.com!d11no139430qth.0!postnews."
      @"google.com!glegroupsg2000goo.googlegroups.com!not-for-mail\r\n"
      @"Newsgroups: comp.lang.python\r\n"
      @"Date: Mon, 2 Apr 2018 20:01:12 -0700 (PDT)\r\n"
      @"In-Reply-To: <mailman.105.1522676213.3863.python-list@python.org>\r\n"
      @"Complaints-To: groups-abuse@google.com\r\n"
      @"Injection-Info: glegroupsg2000goo.googlegroups.com;\r\n"
      @" posting-host=114.40.191.59;\r\n"
      @" posting-account=G2sM6AoAAADOlDdo9rWD6sFkj3T5ULsz\r\n"
      @"NNTP-Posting-Host: 114.40.191.59\r\n"
      @"References: <5325545a-9fe8-4ffd-ab84-0e3468ff7bb9@googlegroups.com> "
      @"<CALwzid=CeE7RkW01oyJT8mVbTQC_eKJjgmSQXTiyC2ocsj87qA@mail.gmail.com> "
      @"<mailman.105.1522676213.3863.python-list@python.org>\r\n"
      @"User-Agent: G2/1.0\r\n"
      @"MIME-Version: 1.0\r\n"
      @"Message-ID: <1c54182f-05f4-4e73-b39d-dd03a05e4bfe@googlegroups.com>\r\n"
      @"Subject: Re: In asyncio, does the event_loop still running after "
      @"run_until_complete returned?\r\n"
      @"From: jfong@ms4.hinet.net\r\n"
      @"Injection-Date: Tue, 03 Apr 2018 03:01:13 +0000\r\n"
      @"Content-Type: text/plain; charset=\"UTF-8\"\r\n"
      @"Content-Transfer-Encoding: quoted-printable\r\n"
      @"Lines: 125\r\n"
      @"Xref: reader02.eternal-september.org\r\n"
      @" comp.lang.python:221442\r\n"
      @"\r\n"
      @"Ian於 2018年4月2日星期一 UTC+8下午9時37分08秒寫道：\r\n"
      @"> On Mon, Apr 2, 2018 at 5:32 AM,  <jfong@ms4.hinet.net> wrote:\r\n"
      @"> > I am new to the asyncio subject, just trying to figure out how to "
      @"use it. Below is the script I use for testing:\r\n";
  NSData *articleData = [article dataUsingEncoding:NSUTF8StringEncoding];
  NNHeaderParser *parser = [[NNHeaderParser alloc] initWithData:articleData];
  NSArray *entries = parser.entries;
  XCTAssertEqual(entries.count, 20, "Unexpected number of headers");

  NNHeaderEntry *entry = parser.entries[19];
  XCTAssert([entry.name isEqualToString:@"Xref"], "Unexpected header name");
  XCTAssert([entry.value
                isEqualToString:
                    @"reader02.eternal-september.org comp.lang.python:221442"],
            "Unexpected header value");
}

- (void)testEmptyHeaders {
  NSString *article = @"220 status line (should this be here?)\r\n"
                      @"Heading-1: Heading Value\r\n"
                      @"Heading-2: \r\n"
                      @"Heading-3:\r\n"
                      @"Heading-4: Heading Value\r\n"
                      @"\r\n"
                      @"Body\r\n";
  NSData *articleData = [article dataUsingEncoding:NSUTF8StringEncoding];
  NNHeaderParser *parser = [[NNHeaderParser alloc] initWithData:articleData];
  XCTAssertEqual(parser.entries.count, 4, "Unexpected number of headers");

  NNHeaderEntry *entry = parser.entries[0];
  XCTAssert([entry.name isEqualToString:@"Heading-1"],
            "Unexpected header 1 name");
  XCTAssert([entry.value isEqualToString:@"Heading Value"],
            "Unexpected header 1 value");

  entry = parser.entries[1];
  XCTAssert([entry.name isEqualToString:@"Heading-2"],
            "Unexpected header 2 name");
  XCTAssert([entry.value isEqualToString:@""], "Unexpected header 2 value");

  entry = parser.entries[2];
  XCTAssert([entry.name isEqualToString:@"Heading-3"],
            "Unexpected header 3 name");
  XCTAssert([entry.value isEqualToString:@""], "Unexpected header 3 value");

  entry = parser.entries[3];
  XCTAssert([entry.name isEqualToString:@"Heading-4"],
            "Unexpected header 4 name");
  XCTAssert([entry.value isEqualToString:@"Heading Value"],
            "Unexpected header 4 value");
}

@end
