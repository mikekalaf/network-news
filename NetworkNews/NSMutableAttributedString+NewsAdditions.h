//
//  NSMutableAttributedString+NewsAdditions.h
//  Network News
//
//  Created by David Schweinsberg on 8/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableAttributedString (NewsAdditions)

//- (void)appendNewsData:(NSData *)data;

- (void)appendNewsHead:(NSArray *)entries;

- (void)appendNewsBody:(NSData *)data flowed:(BOOL)isFlowed;

@end
