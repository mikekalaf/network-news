//
//  Attachment.h
//  Network News
//
//  Created by David Schweinsberg on 4/03/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ArticlePartContent;
@class ContentType;

@interface Attachment : NSObject

@property(nonatomic, copy, readonly) NSString *fileName;
@property(nonatomic, readonly) NSData *data;
@property(nonatomic, readonly) NSRange rangeInArticleData;

-   (id)initWithContent:(ArticlePartContent *)content
            contentType:(ContentType *)contentType
contentTransferEncoding:(NSString *)contentTransferEncoding;

@end
