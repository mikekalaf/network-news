//
//  QuotedPrintableDecoder.h
//  Network News
//
//  Created by David Schweinsberg on 1/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QuotedPrintableDecoder : NSObject
{

}

+ (BOOL)isQuotedPrintable:(NSArray *)headers;

- (NSData *)decodeData:(NSData *)data;

@end
