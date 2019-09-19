//
//  NNNewsrc.h
//  NetworkNews
//
//  Created by David Schweinsberg on 22/11/2013.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NNNewsrc : NSObject

- (instancetype)initWithServerName:(NSString *)serverName
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));
- (void)sync;
- (BOOL)isReadForGroupName:(NSString *)name articleNumber:(long long)number;
- (void)setRead:(BOOL)read
     forGroupName:(NSString *)name
    articleNumber:(long long)number;
@property(NS_NONATOMIC_IOSONLY, copy) NSArray *subscribedGroupNames;

@end
