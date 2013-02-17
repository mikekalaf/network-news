//
//  NNHeaderParser.h
//  Network News
//
//  Created by David Schweinsberg on 8/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NNHeaderParser : NSObject
{
    NSData *data;
    NSUInteger length;
    NSArray *entries;
}

@property (readonly) NSUInteger length;
@property (readonly) NSArray *entries;

- (id)initWithData:(NSData *)articleData;

@end