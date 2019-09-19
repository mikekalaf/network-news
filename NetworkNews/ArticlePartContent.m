//
//  ArticlePartContent.m
//  Network News
//
//  Created by David Schweinsberg on 19/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ArticlePartContent.h"
#import "NNHeaderParser.h"

@implementation ArticlePartContent

@synthesize data;

- (instancetype)initWithHead:(BOOL)withHead {
  self = [super init];
  if (self) {
    containsHead = withHead;
    data = [[NSMutableData alloc] initWithCapacity:1];
  }
  return self;
}

- (void)collectHeadEntries {
  if (containsHead && headEntries == nil) {
    // Initialise the head and body ranges
    NNHeaderParser *hp = [[NNHeaderParser alloc] initWithData:data];
    headEntries = hp.entries;

    headRange = NSMakeRange(0, hp.length);
    bodyRange = NSMakeRange(hp.length, data.length - hp.length);
  }
}

- (NSArray *)headEntries {
  [self collectHeadEntries];
  return headEntries;
}

- (NSRange)headRange {
  [self collectHeadEntries];
  return headRange;
}

- (NSRange)bodyRange {
  [self collectHeadEntries];
  return bodyRange;
}

- (NSData *)bodyData {
  if (containsHead && bodyData == nil) {
    [self collectHeadEntries];
    bodyData = [data subdataWithRange:bodyRange];
  }

  if (bodyData)
    return bodyData;
  else
    return data;
}

@end
