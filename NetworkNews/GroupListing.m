// 
//  GroupListing.m
//  Network News
//
//  Created by David Schweinsberg on 5/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "GroupListing.h"

@implementation GroupListing 

- (id)initWithName:(NSString *)name
    highestArticle:(long long)highestArticle
     lowestArticle:(long long)lowestArticle
     postingStatus:(char)postingStatus
{
    self = [super init];
    if (self)
    {
        _name = name;
        _highestArticle = highestArticle;
        _lowestArticle = lowestArticle;
        _postingStatus = postingStatus;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        _name = [aDecoder decodeObjectForKey:@"Name"];
        _highestArticle = [aDecoder decodeInt64ForKey:@"High"];
        _lowestArticle = [aDecoder decodeInt64ForKey:@"Low"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeInt64:_highestArticle forKey:@"highestArticle"];
    [aCoder encodeInt64:_lowestArticle forKey:@"lowestArticle"];
}

- (long long)count
{
    return _highestArticle - _lowestArticle + 1;
}

//- (NSRange)rangeOfLatestArticlesFromLowestArticleNumber:(long long)lowestArticleNumber
//                                   highestArticleNumber:(long long)highestArticleNumber
//                                                inGroup:(GroupListing *)group
//{
//    //    long long lowestLoaded = group.lowestArticleNumber.longLongValue;
//    long long highestLoaded = group.highestArticle;
//    if (highestLoaded < highestArticleNumber)
//    {
//        long long lowestNew;
//        if (highestLoaded <= lowestArticleNumber)
//            lowestNew = lowestArticleNumber;
//        else
//            lowestNew = highestLoaded + 1;
//
//        NSLog(@"LATEST range: location = %lld, length = %lld", lowestNew, highestArticleNumber - lowestNew + 1);
//
//        return NSMakeRange(lowestNew, highestArticleNumber - lowestNew + 1);
//    }
//    return NSMakeRange(highestArticleNumber, 0);
//}
//
//- (NSRange)rangeOfMoreArticlesFromLowestArticleNumber:(long long)lowestArticleNumber
//                                              inGroup:(GroupListing *)group
//{
//    long long lowestLoaded = group.lowestArticle;
//    //    long long highestLoaded = group.highestArticleNumber.longLongValue;
//    if (lowestArticleNumber < lowestLoaded)
//    {
//        NSLog(@"MORE range: location = %lld, length = %lld", lowestArticleNumber, lowestLoaded - lowestArticleNumber);
//
//        return NSMakeRange(lowestArticleNumber, lowestLoaded - lowestArticleNumber);
//    }
//    return NSMakeRange(lowestArticleNumber, 0);
//}

@end
