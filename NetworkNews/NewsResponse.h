//
//  NewsResponse.h
//  NetworkNews
//
//  Created by David Schweinsberg on 8/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NewsResponse : NSObject

@property(nonatomic, readonly) NSData *data;
@property(nonatomic, readonly) NSInteger statusCode;
@property(nonatomic) NSDictionary *dictionary;

- (instancetype)initWithData:(NSData *)data
                  statusCode:(NSInteger)statusCode NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@property(NS_NONATOMIC_IOSONLY, readonly, copy) NSString *string;

@end
