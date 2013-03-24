//
//  NewsAccount.h
//  NetworkNews
//
//  Created by David Schweinsberg on 2/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    AccountTemplateDefault = 0,
    AccountTemplateGiganews
} AccountTemplate;


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

+ (id)accountWithTemplate:(AccountTemplate)accountTemplate;

@end
