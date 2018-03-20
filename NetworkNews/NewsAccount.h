//
//  NewsAccount.h
//  NetworkNews
//
//  Created by David Schweinsberg on 2/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(unsigned int, AccountTemplate)
{
    AccountTemplateDefault = 0,
    AccountTemplateEternalSeptember
};

@class NNNewsrc;

@interface NewsAccount : NSObject <NSCoding>

@property (nonatomic) AccountTemplate accountTemplate;
@property (nonatomic) NSString *serviceName;
@property (nonatomic) NSURL *supportURL;
@property (nonatomic) NSString *iconName;
@property (nonatomic) NSString *hostName;
@property (nonatomic) NSUInteger port;
@property (nonatomic, getter = isSecure) BOOL secure;
@property (nonatomic) NSString *userName;
@property (nonatomic) NSString *password;

@property (nonatomic, readonly) NSURL *cacheURL;
@property (nonatomic, readonly) NNNewsrc *newsrc;

+ (instancetype)accountWithTemplate:(AccountTemplate)accountTemplate;

@end
