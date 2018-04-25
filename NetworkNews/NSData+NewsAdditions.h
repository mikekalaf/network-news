//
//  NSData+NewsAdditions.h
//  Network News
//
//  Created by David Schweinsberg on 4/03/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (NewsAdditions)

@property(readonly) NSUInteger CRC32;

- (NSData *)dataWithCRLFs;

@end
