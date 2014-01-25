//
//  ArticleRange.h
//  NetworkNews
//
//  Created by David Schweinsberg on 15/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct _ArticleRange
{
    uint64_t location;
    uint64_t length;
} ArticleRange;

NS_INLINE ArticleRange ArticleRangeMake(uint64_t loc, uint64_t len)
{
    ArticleRange r;
    r.location = loc;
    r.length = len;
    return r;
}

NS_INLINE uint64_t ArticleRangeMax(ArticleRange range)
{
    return (range.location + range.length);
}

NS_INLINE BOOL LocationInArticleRange(uint64_t loc, ArticleRange range)
{
    return (loc - range.location < range.length);
}

NS_INLINE BOOL EqualArticleRanges(ArticleRange range1, ArticleRange range2)
{
    return (range1.location == range2.location && range1.length == range2.length);
}

@interface NSValue (ArticleRange)

+ (NSValue *)valueWithArticleRange:(ArticleRange)range;

- (ArticleRange)articleRangeValue;

@end
