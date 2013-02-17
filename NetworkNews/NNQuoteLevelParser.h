//
//  NNQuoteLevelParser.h
//  Network News
//
//  Created by David Schweinsberg on 28/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NNQuoteLevelParser : NSObject
{
    NSData *data;
    BOOL flowed;
}

@property(retain, readonly) NSArray *quoteLevels;

- (id)initWithData:(NSData *)aData
            flowed:(BOOL)isFlowed;

@end
