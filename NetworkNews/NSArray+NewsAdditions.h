//
//  NSArray+NewsAdditions.h
//  Network News
//
//  Created by David Schweinsberg on 30/11/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (NewsAdditions)

- (NSObject *)head;
- (NSArray *)tail;
- (id)objectWithName:(NSString *)name;

@end
