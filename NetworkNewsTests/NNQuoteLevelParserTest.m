//
//  NNQuoteLevelParserTest.m
//  NetworkNewsTests
//
//  Created by David Schweinsberg on 4/13/18.
//  Copyright © 2018 David Schweinsberg. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NNQuoteLevelParser.h"
#import "NNQuoteLevel.h"

@interface NNQuoteLevelParserTest : XCTestCase

@end

@implementation NNQuoteLevelParserTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testQuoteLevels {
    NSString *str = @">Level One\r\n>>Level Two\r\n>>>Level Three\r\n>>Level Two\r\n";
    NSData *strData = [str dataUsingEncoding:NSASCIIStringEncoding];
    NNQuoteLevelParser* parser = [[NNQuoteLevelParser alloc] initWithData:strData flowed:NO];
    NSArray *quoteLevels = parser.quoteLevels;
    XCTAssertEqual(quoteLevels.count, 4);
    NNQuoteLevel *quoteLevel = quoteLevels[0];
    XCTAssertEqual(quoteLevel.level, 1);
    quoteLevel = quoteLevels[1];
    XCTAssertEqual(quoteLevel.level, 2);
    quoteLevel = quoteLevels[2];
    XCTAssertEqual(quoteLevel.level, 3);
    quoteLevel = quoteLevels[3];
    XCTAssertEqual(quoteLevel.level, 2);
}

- (void)testSignatureDetection {
    NSString *str =
    @"First line\r\n"
    @"Second line\r\n"
    @"-- \r\n"
    @"Signature Line\r\n";
    NSData *strData = [str dataUsingEncoding:NSASCIIStringEncoding];
    NNQuoteLevelParser* parser = [[NNQuoteLevelParser alloc] initWithData:strData flowed:NO];
    NSArray *quoteLevels = parser.quoteLevels;
    XCTAssertEqual(quoteLevels.count, 4);
    NNQuoteLevel *quoteLevel = quoteLevels[0];
    XCTAssertFalse(quoteLevel.signatureDivider);
    quoteLevel = quoteLevels[1];
    XCTAssertFalse(quoteLevel.signatureDivider);
    quoteLevel = quoteLevels[2];
    XCTAssertTrue(quoteLevel.signatureDivider);
    quoteLevel = quoteLevels[3];
    XCTAssertFalse(quoteLevel.signatureDivider);
}

@end
