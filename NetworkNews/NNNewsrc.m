//
//  NNNewsrc.m
//  NetworkNews
//
//  Created by David Schweinsberg on 22/11/2013.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "NNNewsrc.h"
#import "ArticleRange.h"

@interface NNNewsrc ()
{
    NSMutableDictionary *_groups;
    NSString *_serverName;
    NSURL *_fileURL;
    BOOL changed;
}

@end


@implementation NNNewsrc

- (id)initWithServerName:(NSString *)serverName
{
    self = [super init];
    if (self)
    {
        _groups = [[NSMutableDictionary alloc] init];
        _serverName = [serverName copy];

        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSURL *url = [[fileManager URLsForDirectory:NSDocumentDirectory
                                          inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:_serverName];
        _fileURL = [url URLByAppendingPathComponent:@"newsrc"];
        [self readNewsrcFileAtURL:_fileURL];
        changed = NO;
    }
    return self;
}

- (void)sync
{
    if (changed)
        [self writeNewsrcFileAtURL:_fileURL];
    changed = NO;
}

- (BOOL)isReadForGroupName:(NSString *)name articleNumber:(long long)number
{
    NSMutableArray *articleRanges = [_groups objectForKey:name];
    for (NSValue *rangeObject in articleRanges)
    {
        ArticleRange range = [rangeObject articleRangeValue];
        if (range.location <= number && number <= range.location + range.length)
            return YES;
    }
    return NO;
}

- (void)setRead:(BOOL)read forGroupName:(NSString *)name articleNumber:(long long)number
{
    NSMutableArray *articleRanges = [_groups objectForKey:name];
    if (articleRanges == nil)
    {
        articleRanges = [[NSMutableArray alloc] init];
        _groups[name] = articleRanges;
    }

    // Find existing range containing number or adjacent ranges
    NSValue *followingRange = nil;
    NSValue *precedingRange = nil;
    for (NSValue *rangeObject in articleRanges)
    {
        ArticleRange range = [rangeObject articleRangeValue];
        if (range.location <= number && number <= range.location + range.length)
            return;

        if (number == [rangeObject articleRangeValue].location - 1)
            followingRange = rangeObject;

        if (number == ArticleRangeMax([rangeObject articleRangeValue]) + 1)
            precedingRange = rangeObject;
    }

    // Create a new range, or merge into one or both adjacent ranges
    NSValue *newFollowingRange = nil;
    NSValue *newPrecedingRange = nil;
    if (precedingRange == nil && followingRange == nil)
    {
        // New range
        [articleRanges addObject:[NSValue valueWithArticleRange:ArticleRangeMake(number, 0)]];
    }
    else if (precedingRange != nil && followingRange == nil)
    {
        // Append to preceding range
        ArticleRange range = [precedingRange articleRangeValue];
        range.length += 1;
        newPrecedingRange = [NSValue valueWithArticleRange:range];
    }
    else if (precedingRange == nil && followingRange != nil)
    {
        // Append to following range
        ArticleRange range = [followingRange articleRangeValue];
        range.location -= 1;
        range.length += 1;
        newFollowingRange = [NSValue valueWithArticleRange:range];
    }
    else
    {
        // Merge preceding range, new number, and following range into one
        ArticleRange range1 = [precedingRange articleRangeValue];
        ArticleRange range2 = [followingRange articleRangeValue];
        range1.length += range2.length + 2;
        newPrecedingRange = [NSValue valueWithArticleRange:range1];
    }

    // Replace the modified ranges within the array
    if (precedingRange)
    {
        NSUInteger index = [articleRanges indexOfObject:precedingRange];
        [articleRanges replaceObjectAtIndex:index withObject:newPrecedingRange];
    }

    if (followingRange)
    {
        NSUInteger index = [articleRanges indexOfObject:followingRange];
        if (newFollowingRange)
            [articleRanges replaceObjectAtIndex:index withObject:newFollowingRange];
        else
            [articleRanges removeObjectAtIndex:index];
    }

    changed = YES;
}

- (void)readNewsrcFileAtURL:(NSURL *)url
{
    NSInputStream *stream = [[NSInputStream alloc] initWithURL:url];
    [stream open];

    if ([stream streamStatus] == NSStreamStatusError)
        return;

    while (YES)
    {
        char buf[255] = { 0 };
        char *ptr = buf;
        BOOL eos = NO;

        // Read the newsgroup name
        while (ptr - buf < 255)
        {
            if ([stream read:(uint8_t *)ptr maxLength:1] <= 0)
            {
                eos = YES;
                break;
            }
            if (*ptr == ':' || *ptr == '!')
                break;
            ++ptr;
        }

        if (eos)
            break;

        NSString *name = [[NSString alloc] initWithBytes:buf
                                                  length:ptr - buf
                                                encoding:NSUTF8StringEncoding];
        NSMutableArray *articleRanges = [[NSMutableArray alloc] init];
        _groups[name] = articleRanges;

        BOOL subscribed = *ptr == ':';

        // Read the ranges
        BOOL moreValues = YES;
        while (moreValues)
        {
            ptr = buf;
            while (ptr - buf < 255)
            {
                [stream read:(uint8_t *)ptr maxLength:1];
                if (*ptr == ',' || *ptr == '\n')
                {
                    moreValues = *ptr == ',';
                    *ptr = 0;
                    break;
                }
                ++ptr;
            }

            // Is this a range or a single number?
            NSUInteger len = ptr - buf;
            BOOL range = NO;
            NSUInteger i;
            for (i = 0; i < len; ++i)
            {
                if (buf[i] == '-')
                {
                    buf[i] = 0;
                    range = YES;
                    break;
                }
            }

            if (range)
            {
                long long n1 = atoll(buf);
                long long n2 = atoll(buf + i + 1);
                ArticleRange range = ArticleRangeMake(n1, n2 - n1);
                [articleRanges addObject:[NSValue valueWithArticleRange:range]];
            }
            else
            {
                long long n = atoll(buf);
                ArticleRange range = ArticleRangeMake(n, 0);
                [articleRanges addObject:[NSValue valueWithArticleRange:range]];
            }
        }
    }

    [stream close];
}

- (void)writeNewsrcFileAtURL:(NSURL *)url
{
    NSOutputStream *stream = [[NSOutputStream alloc] initWithURL:url append:NO];
    [stream open];
    for (NSString *key in [_groups allKeys])
    {
        [stream write:(const uint8_t *)[key cStringUsingEncoding:NSUTF8StringEncoding]
            maxLength:[key length]];
        [stream write:(const uint8_t *)": " maxLength:2];

        NSArray *values = _groups[key];
        BOOL comma = NO;
        for (NSValue *value in values)
        {
            if (comma)
                [stream write:(const uint8_t *)"," maxLength:1];
            comma = YES;
            ArticleRange range = [value articleRangeValue];
            char buf[255];
            if (range.length == 0)
                snprintf(buf, 255, "%llu", range.location);
            else
                snprintf(buf, 255, "%llu-%llu", range.location, range.location + range.length);
            [stream write:(const uint8_t *)buf maxLength:strlen(buf)];
        }
        [stream write:(const uint8_t *)"\n" maxLength:1];
    }
    [stream close];
}

@end
