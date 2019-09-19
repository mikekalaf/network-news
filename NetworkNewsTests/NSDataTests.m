//
//  NSDataTests.m
//  NetworkNewsTests
//
//  Created by David Schweinsberg on 4/17/18.
//  Copyright © 2018 David Schweinsberg. All rights reserved.
//

#import "NSData+NewsAdditions.h"
#import "NSString+NewsAdditions.h"
#import <XCTest/XCTest.h>

@interface NSDataTests : XCTestCase

@end

@implementation NSDataTests

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

- (void)testLF {
  // Tranform LFs into CRLFs
  // (This should be the normal situation when dealing with text in text boxes)
  NSString *text = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit";
  text = [text stringByWrappingUnquotedWordsAtColumn:11];

  NSData *textData = [text dataUsingEncoding:NSASCIIStringEncoding];
  const char *withLF =
      "Lorem \nipsum \ndolor sit \namet, \nconsectetur \nadipisicing \nelit";
  XCTAssertEqual(textData.length, strlen(withLF),
                 "ASCII string lengths are different");
  XCTAssertEqual(strncmp(textData.bytes, withLF, 62), 0,
                 "ASCII strings don't match");

  NSData *textDataWithCRLF = [textData dataWithCRLFs];
  const char *withCRLF = "Lorem \r\nipsum \r\ndolor sit \r\namet, "
                         "\r\nconsectetur \r\nadipisicing \r\nelit";
  XCTAssertEqual(textDataWithCRLF.length, strlen(withCRLF),
                 "ASCII string lengths are different");
  XCTAssertEqual(strncmp(textDataWithCRLF.bytes, withCRLF, 68), 0,
                 "ASCII strings don't match");
}

- (void)testCR {
  // Any stray CRs should have LFs appended (should be less likely)
  NSString *text =
      @"Lorem ipsum \rdolor sit amet, \rconsectetur adipisicing elit";
  NSData *textData = [text dataUsingEncoding:NSASCIIStringEncoding];
  NSData *textDataWithCRLF = [textData dataWithCRLFs];
  const char *withCRLF =
      "Lorem ipsum \r\ndolor sit amet, \r\nconsectetur adipisicing elit";
  XCTAssertEqual(textDataWithCRLF.length, strlen(withCRLF),
                 "ASCII string lengths are different");
  XCTAssertEqual(strncmp(textDataWithCRLF.bytes, withCRLF, 60), 0,
                 "ASCII strings don't match");
}

- (void)testCRLF {
  // CRLFs should pass through without alteration
  NSString *text =
      @"Lorem ipsum \r\ndolor sit amet, \r\nconsectetur adipisicing elit";
  NSData *textData = [text dataUsingEncoding:NSASCIIStringEncoding];
  NSData *textDataWithCRLF = [textData dataWithCRLFs];
  const char *withCRLF =
      "Lorem ipsum \r\ndolor sit amet, \r\nconsectetur adipisicing elit";
  XCTAssertEqual(textDataWithCRLF.length, strlen(withCRLF),
                 "ASCII string lengths are different");
  XCTAssertEqual(strncmp(textDataWithCRLF.bytes, withCRLF, 60), 0,
                 "ASCII strings don't match");
}

@end
