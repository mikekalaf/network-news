//
//  NSStringTests.m
//  NetworkNewsTests
//
//  Created by David Schweinsberg on 4/17/18.
//  Copyright © 2018 David Schweinsberg. All rights reserved.
//

#import "NSString+NewsAdditions.h"
#import <XCTest/XCTest.h>

@interface NSStringTests : XCTestCase

@end

@implementation NSStringTests

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

- (void)testWrappingRanges {
  NSString *text = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit";
  NSArray *ranges = [text rangesWrappingWordsAtColumn:11];
  XCTAssertEqual(ranges.count, 7, "Wrong number of ranges");
  NSRange range = [ranges[0] rangeValue];
  XCTAssertEqual(range.location, 0);
  XCTAssertEqual(range.length, 6);
  range = [ranges[1] rangeValue];
  XCTAssertEqual(range.location, 6);
  XCTAssertEqual(range.length, 6);
  range = [ranges[2] rangeValue];
  XCTAssertEqual(range.location, 12);
  XCTAssertEqual(range.length, 10);
  range = [ranges[3] rangeValue];
  XCTAssertEqual(range.location, 22);
  XCTAssertEqual(range.length, 6);
  range = [ranges[4] rangeValue];
  XCTAssertEqual(range.location, 28);
  XCTAssertEqual(range.length, 12);
  range = [ranges[5] rangeValue];
  XCTAssertEqual(range.location, 40);
  XCTAssertEqual(range.length, 12);
  range = [ranges[6] rangeValue];
  XCTAssertEqual(range.location, 52);
  XCTAssertEqual(range.length, 4);
}

- (void)testWrappingRangesWithQuoteBeginning {
  NSString *text = @">one two three\n"
                   @"four five six\n"
                   @"seven eight nine\n";
  NSArray *ranges = [text rangesWrappingWordsAtColumn:3];
  XCTAssertEqual(ranges.count, 7, "Wrong number of ranges");
  NSRange range = [ranges[0] rangeValue];
  XCTAssertEqual(range.location, 0);
  XCTAssertEqual(range.length, 14);
  range = [ranges[1] rangeValue];
  XCTAssertEqual(range.location, 15);
  XCTAssertEqual(range.length, 5);
  range = [ranges[2] rangeValue];
  XCTAssertEqual(range.location, 20);
  XCTAssertEqual(range.length, 5);
  range = [ranges[3] rangeValue];
  XCTAssertEqual(range.location, 25);
  XCTAssertEqual(range.length, 3);
}

- (void)testWrappingRangesWithQuoteMiddle {
  NSString *text = @"one two three\n"
                   @">four five six\n"
                   @"seven eight nine\n";
  NSArray *ranges = [text rangesWrappingWordsAtColumn:3];
  XCTAssertEqual(ranges.count, 7, "Wrong number of ranges");
}

- (void)testWrappingRangesWithQuoteEnd {
  NSString *text = @"one two three\n"
                   @"four five six\n"
                   @">seven eight nine\n";
  NSArray *ranges = [text rangesWrappingWordsAtColumn:3];
  XCTAssertEqual(ranges.count, 7, "Wrong number of ranges");
}

- (void)testWrappingRangesWithQuoteEndNoLF {
  NSString *text = @"one two three\n"
                   @"four five six\n"
                   @">seven eight nine";
  NSArray *ranges = [text rangesWrappingWordsAtColumn:3];
  XCTAssertEqual(ranges.count, 7, "Wrong number of ranges");
}

- (void)testWrappingRangesWithBlankQuote {
  NSString *text = @"one two three\n"
                   @">four five six\n"
                   @">\n"
                   @"seven eight nine\n";
  NSArray *ranges = [text rangesWrappingWordsAtColumn:3];
  XCTAssertEqual(ranges.count, 8, "Wrong number of ranges");
  NSRange range = [ranges[4] rangeValue];
  XCTAssertEqual(range.location, 29);
  XCTAssertEqual(range.length, 1);
}

- (void)testWrappingRangesWithLineBreak {
  NSString *text = @"Lorem ipsum dolor sit amet,\nconsectetur adipisicing elit";
  NSArray *ranges = [text rangesWrappingWordsAtColumn:20];
  XCTAssertEqual(ranges.count, 4, "Wrong number of ranges");
  NSRange range = [ranges[0] rangeValue];
  XCTAssertEqual(range.location, 0);
  XCTAssertEqual(range.length, 18);
  range = [ranges[1] rangeValue];
  XCTAssertEqual(range.location, 18);
  XCTAssertEqual(range.length, 9); // Do not count the LF
  range = [ranges[2] rangeValue];
  XCTAssertEqual(range.location, 28);
  XCTAssertEqual(range.length, 12);
  range = [ranges[3] rangeValue];
  XCTAssertEqual(range.location, 40);
  XCTAssertEqual(range.length, 16);
}

- (void)testWrappingRangesWithTrailingLineBreak {
  NSString *text = @"Lorem ipsum\n";
  NSArray *ranges = [text rangesWrappingWordsAtColumn:20];
  XCTAssertEqual(ranges.count, 1, "Wrong number of ranges");
  NSRange range = [ranges[0] rangeValue];
  XCTAssertEqual(range.location, 0);
  XCTAssertEqual(range.length, 11);
}

//- (void)testWrappingRangesWithTrailingCRLF {
//    NSString *text = @"Lorem ipsum\r\n";
//    NSArray *ranges = [text rangesWrappingWordsAtColumn:20];
//    XCTAssertEqual(ranges.count, 1, "Wrong number of ranges");
//    NSRange range = [ranges[0] rangeValue];
//    XCTAssertEqual(range.location, 0);
//    XCTAssertEqual(range.length, 11);
//}

//- (void)testWrappingQuotedRanges {
//    NSString *text =
//    @"Lorem ipsum dolor sit amet, consectetur adipisicing elit\n"
//    @"> Lorem ipsum dolor sit amet, consectetur adipisicing elit\n"
//    @"Lorem ipsum dolor sit amet, consectetur adipisicing elit\n";
//    NSArray *ranges = [text rangesWrappingWordsAtColumn:11];
//    XCTAssertEqual(ranges.count, 15, "Wrong number of ranges");
//}

- (void)testWrappingRangesWithExtraSpaces {
  NSString *text = @"Lorem      ipsum";
  NSArray *ranges = [text rangesWrappingWordsAtColumn:7];
  XCTAssertEqual(ranges.count, 2, "Wrong number of ranges");
  NSRange range = [ranges[0] rangeValue];
  XCTAssertEqual(range.location, 0);
  XCTAssertEqual(range.length, 6);
  range = [ranges[1] rangeValue];
  XCTAssertEqual(range.location, 11);
  XCTAssertEqual(range.length, 5);
}

- (void)testWrapping {
  NSString *text = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit";
  text = [text stringByWrappingUnquotedWordsAtColumn:11];
  XCTAssert([text isEqualToString:@"Lorem \nipsum \ndolor sit \namet, "
                                  @"\nconsectetur \nadipisicing \nelit"]);
}

- (void)testNarrowWrapping {
  NSString *text = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit";
  text = [text stringByWrappingUnquotedWordsAtColumn:5];
  XCTAssert([text isEqualToString:@"Lorem \nipsum \ndolor \nsit \namet, "
                                  @"\nconsectetur \nadipisicing \nelit"]);
}

- (void)testWrappingWithQuotes {
  NSString *text =
      @"Lorem ipsum dolor sit amet, consectetur adipisicing elit\n"
      @"> Lorem ipsum dolor sit amet, consectetur adipisicing elit\n"
      @"Lorem ipsum dolor sit amet, consectetur adipisicing elit\n";
  text = [text stringByWrappingUnquotedWordsAtColumn:11];
  XCTAssert(
      [text isEqualToString:
                @"Lorem \nipsum \ndolor sit \namet, \nconsectetur "
                @"\nadipisicing \nelit\n"
                @"> Lorem ipsum dolor sit amet, consectetur adipisicing elit\n"
                @"Lorem \nipsum \ndolor sit \namet, \nconsectetur "
                @"\nadipisicing \nelit"]);
  NSLog(@"Text: %@", text);
}

@end
