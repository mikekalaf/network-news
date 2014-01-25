//
//  ArticleRange.h
//  NetworkNews
//
//  Created by David Schweinsberg on 25/01/14.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "ArticleRange.h"

@implementation NSValue (ArticleRange)

+ (NSValue *)valueWithArticleRange:(ArticleRange)range
{
    return [NSValue valueWithBytes:&range objCType:@encode(ArticleRange)];
}

- (ArticleRange)articleRangeValue
{
    ArticleRange range;
    [self getValue:&range];
    return range;
}

@end
