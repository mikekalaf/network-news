//
//  NSData+NewsAdditions.m
//  Network News
//
//  Created by David Schweinsberg on 4/03/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NSData+NewsAdditions.h"
#import <zlib.h>

@implementation NSData (NewsAdditions)

- (NSUInteger)CRC32
{
    return crc32(0, self.bytes, (unsigned int)self.length);
}

@end
