//
//  NewsConnection.h
//  NetworkNews
//
//  Created by David Schweinsberg on 8/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArticleRange.h"

extern NSString *const NewsConnectionBytesReceivedNotification;

@class NewsResponse;

@interface NewsConnection : NSObject

@property(nonatomic, readonly) NSString *welcome;

- (instancetype)initWithHost:(NSString *)host port:(NSUInteger)port isSecure:(BOOL)secure NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

- (NSUInteger)loginWithUser:(NSString *)user password:(NSString *)password;
- (NewsResponse *)listActiveWithWildmat:(NSString *)wildmat;
- (NewsResponse *)articleWithMessageID:(NSString *)messageID;
- (NewsResponse *)bodyWithMessageID:(NSString *)messageID;
- (NewsResponse *)groupWithName:(NSString *)groupName;
- (NewsResponse *)overWithRange:(ArticleRange)articleRange;
- (NewsResponse *)quit;
- (NewsResponse *)capabilities;
- (NewsResponse *)help;
- (NewsResponse *)postData:(NSData *)data;

@end
