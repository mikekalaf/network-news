//
//  NSMutableAttributedStringTests.m
//  NetworkNewsTests
//
//  Created by David Schweinsberg on 4/25/18.
//  Copyright © 2018 David Schweinsberg. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSMutableAttributedString+NewsAdditions.h"
#import "NNHeaderEntry.h"

@interface NSMutableAttributedStringTests : XCTestCase

@end

@implementation NSMutableAttributedStringTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAppendNewsHead {
    NSArray *headers = @[[[NNHeaderEntry alloc] initWithName:@"Header-1" value:@"Value-1"],
                         [[NNHeaderEntry alloc] initWithName:@"Header-2" value:@"Value-2"]];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];
    [attrString appendNewsHead:headers];
    XCTAssert([attrString.string isEqualToString:@"Header-1: Value-1\nHeader-2: Value-2\n"]);
}

- (void)testAppendShortNewsHead {
    NSArray *headers = @[[[NNHeaderEntry alloc] initWithName:@"Header-1" value:@"Value-1"],
                         [[NNHeaderEntry alloc] initWithName:@"From" value:@"Value-From"],
                         [[NNHeaderEntry alloc] initWithName:@"Subject" value:@"Value-Subject"],
                         [[NNHeaderEntry alloc] initWithName:@"Header-2" value:@"Value-2"]];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];
    [attrString appendShortNewsHead:headers];
    XCTAssert([attrString.string isEqualToString:@"From: Value-From\nSubject: Value-Subject\n"]);
}

- (void)testAppendNewsBody {
    NSString *body = @"Line 1\r\nLine 2\r\nLine 3\r\n";
    NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];
    [attrString appendNewsBody:bodyData flowed:NO];
    XCTAssert([attrString.string isEqualToString:@"Line 1\nLine 2\nLine 3\n"]);
}

- (void)testAppendNewsBodyFlowed {
    NSString *body = @"Fragment 1 \r\nFragment 2\r\nFragment 3 \r\nFragment 4\r\n";
    NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];
    [attrString appendNewsBody:bodyData flowed:YES];
    XCTAssert([attrString.string isEqualToString:@"Fragment 1 Fragment 2\nFragment 3 Fragment 4\n"]);
}

@end
