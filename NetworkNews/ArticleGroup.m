// 
//  ArticleGroup.m
//  Network News
//
//  Created by David Schweinsberg on 19/03/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ArticleGroup.h"

#import "Article.h"

@implementation ArticleGroup 

@dynamic name;
@dynamic type;
@dynamic complete;
@dynamic articles;

- (NSString *)shortName
{
    // Represents all hierarchy levels, except the last, just by its initial
    NSArray *components = [self.name componentsSeparatedByString:@"."];
    NSMutableString *shortName = [NSMutableString string];
    NSUInteger index = 0;
    for (NSString *str in components)
    {
        if (index == components.count)
            [shortName appendString:str];
        else
            [shortName appendFormat:@"%c.", [str characterAtIndex:0]];
        ++index;
    }
    return shortName;
}

@end
