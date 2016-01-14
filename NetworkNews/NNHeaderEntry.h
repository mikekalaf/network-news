//
//  NNHeaderEntry.h
//  Network News
//
//  Created by David Schweinsberg on 8/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NNHeaderEntry : NSObject
{
    NSString *name;
    NSString *value;
}

@property (copy, readonly) NSString *name;
@property (copy, readonly) NSString *value;

- (instancetype)initWithName:(NSString *)aName value:(NSString *)aValue NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@end
