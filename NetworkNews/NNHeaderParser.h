//
//  NNHeaderParser.h
//  Network News
//
//  Created by David Schweinsberg on 8/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NNHeaderParser : NSObject

@property(nonatomic, readonly) NSUInteger length;
@property(nonatomic, readonly) NSArray *entries;

- (instancetype)initWithData:(NSData *)articleData NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@end
