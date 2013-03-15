//
//  NewsConnection.h
//  NetworkNews
//
//  Created by David Schweinsberg on 8/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArticleRange.h"

@class NewsResponse;

@interface NewsConnection : NSObject

@property(nonatomic, readonly) NSString *welcome;

- (id)initWithHost:(NSString *)host port:(NSUInteger)port isSecure:(BOOL)secure;

- (void)loginWithUser:(NSString *)user password:(NSString *)password;
- (NewsResponse *)listActiveWithWildmat:(NSString *)wildmat;
- (NewsResponse *)articleWithMessageID:(NSString *)messageID;
- (NewsResponse *)bodyWithMessageID:(NSString *)messageID;
- (NewsResponse *)groupWithName:(NSString *)groupName;
- (NewsResponse *)overWithRange:(ArticleRange)articleRange;
- (NewsResponse *)quit;
- (NewsResponse *)capabilities;

@end
