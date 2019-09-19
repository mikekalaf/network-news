//
//  NNQuoteLevel.h
//  Network News
//
//  Created by David Schweinsberg on 28/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NNQuoteLevel : NSObject {
  NSUInteger level;
  NSRange range;
  BOOL flowed;
  BOOL signatureDivider;
}

@property(readonly) NSUInteger level;

@property(readonly) NSRange range;

@property BOOL flowed;

@property BOOL signatureDivider;

- (instancetype)initWithLevel:(NSUInteger)aLevel
                        range:(NSRange)aRange
                       flowed:(BOOL)isFlowed
             signatureDivider:(BOOL)isSignatureDivider
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@end
