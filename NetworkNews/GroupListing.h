//
//  GroupListing.h
//  Network News
//
//  Created by David Schweinsberg on 5/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GroupListing : NSObject <NSCoding>

@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) long long highestArticle;
@property(nonatomic, readonly) long long lowestArticle;
@property(nonatomic, readonly) char postingStatus;

- (instancetype)initWithName:(NSString *)name
    highestArticle:(long long)highestArticle
     lowestArticle:(long long)lowestArticle
     postingStatus:(char)postingStatus NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@property (NS_NONATOMIC_IOSONLY, readonly) long long count;

@end
