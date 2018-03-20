//
//  NewsAccount.m
//  NetworkNews
//
//  Created by David Schweinsberg on 2/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "NewsAccount.h"
#import "NNNewsrc.h"

@interface NewsAccount ()
{
    NSURL *_cacheURL;
    NNNewsrc *_newsrc;
}

@end


@implementation NewsAccount

+ (instancetype)accountWithTemplate:(AccountTemplate)accountTemplate
{
    NewsAccount *account = [[NewsAccount alloc] init];

    switch (accountTemplate)
    {
        case AccountTemplateEternalSeptember:
            account.accountTemplate = AccountTemplateEternalSeptember;
            account.serviceName = @"Eternal September";
            account.supportURL = [NSURL URLWithString:@"https://www.eternal-september.org"];
            account.iconName = @"es";
            account.hostName = @"news.eternal-september.org";
            [account setSecure:YES];
            account.port = 563;
            break;

        default:
            account.serviceName = @"Usenet Server";
            account.port = 119;
            break;
    }

    return account;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self)
    {
        _accountTemplate = (AccountTemplate)[decoder decodeIntegerForKey:@"accountTemplate"];
        _serviceName = [decoder decodeObjectForKey:@"serviceName"];
        _supportURL = [decoder decodeObjectForKey:@"supportURL"];
        _iconName = [decoder decodeObjectForKey:@"iconName"];
        _hostName = [decoder decodeObjectForKey:@"hostName"];
        _port = [decoder decodeIntegerForKey:@"port"];
        _secure = [decoder decodeBoolForKey:@"secure"];
        _userName = [decoder decodeObjectForKey:@"userName"];
        _password = [decoder decodeObjectForKey:@"password"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInteger:_accountTemplate forKey:@"accountTemplate"];
    [encoder encodeObject:_serviceName forKey:@"serviceName"];
    [encoder encodeObject:_supportURL forKey:@"supportURL"];
    [encoder encodeObject:_iconName forKey:@"iconName"];
    [encoder encodeObject:_hostName forKey:@"hostName"];
    [encoder encodeInteger:_port forKey:@"port"];
    [encoder encodeBool:_secure forKey:@"secure"];
    [encoder encodeObject:_userName forKey:@"userName"];
    [encoder encodeObject:_password forKey:@"password"];
}

- (NSURL *)cacheURL
{
    if (_cacheURL == nil)
    {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        NSURL *rootCacheURL = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].lastObject;
        _cacheURL = [rootCacheURL URLByAppendingPathComponent:_serviceName];

        NSLog(@"Cache root: %@", _cacheURL);

        [fileManager createDirectoryAtURL:_cacheURL
              withIntermediateDirectories:YES
                               attributes:nil
                                    error:NULL];
    }
    return _cacheURL;
}

- (NNNewsrc *)newsrc
{
    if (_newsrc == nil)
    {
        _newsrc = [[NNNewsrc alloc] initWithServerName:self.serviceName];
    }
    return _newsrc;
}

@end
