//
//  UUDecoder.h
//  Network News
//
//  Created by David Schweinsberg on 1/03/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UUDecoder : NSObject
{
    NSData *data;
    NSUInteger begin;
    NSUInteger end;
    NSString *fileName;
    NSRange encodedRange;
}

@property(readonly) NSRange encodedRange;

@property(copy, readonly) NSString *fileName;

+ (BOOL)containsUUEncodedData:(NSData *)data;

- (instancetype)initWithData:(NSData *)encodedData NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *decode;

@end
