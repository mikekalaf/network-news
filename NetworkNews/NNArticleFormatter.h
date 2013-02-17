//
//  NNArticleFormatter.h
//  Network News
//
//  Created by David Schweinsberg on 11/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NNArticleFormatter : NSObject
{

}

+ (NSArray *)headerArrayWithDate:(NSDate *)date
                            from:(NSString *)from
                         replyTo:(NSString *)replyTo
                    organization:(NSString *)organization
                       messageId:(NSString *)messageId
                      references:(NSString *)references
                      newsgroups:(NSString *)newsgroups
                         subject:(NSString *)subject;

- (NSData *)articleDataWithHeaders:(NSArray *)headers
                              text:(NSString *)text
                      formatFlowed:(BOOL)formatFlowed;

@end
