//
//  ArticlePartContent.h
//  Network News
//
//  Created by David Schweinsberg on 19/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArticlePartContent : NSObject {
  NSMutableData *data;
  BOOL containsHead;
  NSArray *headEntries;
  NSRange headRange;
  NSRange bodyRange;
  NSData *bodyData;
}

@property(nonatomic, retain, readonly) NSMutableData *data;

@property(nonatomic, retain, readonly) NSArray *headEntries;

@property(nonatomic, readonly) NSRange headRange;

@property(nonatomic, readonly) NSRange bodyRange;

@property(nonatomic, retain, readonly) NSData *bodyData;

- (instancetype)initWithHead:(BOOL)withHead NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@end
