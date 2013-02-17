//
//  Attachment.h
//  Network News
//
//  Created by David Schweinsberg on 4/03/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ArticlePartContent;

@interface Attachment : NSObject
{
    NSString *fileName;
    NSData *data;
    NSRange rangeInArticleData;
}

@property(nonatomic, copy, readonly) NSString *fileName;

@property(nonatomic, retain, readonly) NSData *data;

@property(nonatomic, readonly) NSRange rangeInArticleData;

- (id)initWithContent:(ArticlePartContent *)content;

@end
