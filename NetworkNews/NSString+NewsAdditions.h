//
//  NSString+NewsAdditions.h
//  Network News
//
//  Created by David Schweinsberg on 27/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (NewsAdditions)

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *shortGroupName;

- (NSString *)stringByWrappingWordsAtColumn:(NSUInteger)location;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *messageIDFileName;

- (NSString *)stringByReplacingOccurrencesOfNumbersWithString:(NSString *)replacement;

@end
