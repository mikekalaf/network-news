//
//  YEncDecoder.h
//  Network News
//
//  Created by David Schweinsberg on 26/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YEncDecoder : NSObject
{
    NSData *data;
    NSUInteger begin;
    NSUInteger end;
    NSString *fileName;
    NSRange encodedRange;
    NSUInteger part;
    NSUInteger size;
    NSUInteger CRC32;
}

@property(readonly) NSRange encodedRange;

@property(copy, readonly) NSString *fileName;

@property(readonly) NSUInteger size;

@property(readonly) NSUInteger CRC32;

+ (BOOL)containsYEncData:(NSData *)data;

- (instancetype)initWithData:(NSData *)encodedData NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *decode;

@end
