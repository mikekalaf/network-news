//
//  NNNewsrc.m
//  NetworkNews
//
//  Created by David Schweinsberg on 22/11/2013.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "NNNewsrc.h"
#import "ArticleRange.h"

@interface NNNewsrcItem : NSObject
@property (nonatomic) NSString *groupName;
@property (nonatomic) BOOL subscribed;
@property (nonatomic) NSMutableArray *articleRanges;
@end

@implementation NNNewsrcItem
@end

@interface NNNewsrc ()
{
    NSMutableArray *_groups;
    NSMutableDictionary *_groupsDictionary;
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
        _groups = [[NSMutableArray alloc] init];
        _groupsDictionary = [[NSMutableDictionary alloc] init];
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
    NNNewsrcItem *item = [_groupsDictionary objectForKey:name];
    for (NSValue *rangeObject in item.articleRanges)
    {
        ArticleRange range = [rangeObject articleRangeValue];
        if (range.location <= number && number <= range.location + range.length)
            return YES;
    }
    return NO;
}

- (void)setRead:(BOOL)read forGroupName:(NSString *)name articleNumber:(long long)number
{
    NNNewsrcItem *item = [_groupsDictionary objectForKey:name];

    // Find existing range containing number or adjacent ranges
    NSValue *followingRange = nil;
    NSValue *precedingRange = nil;
    for (NSValue *rangeObject in item.articleRanges)
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
        [item.articleRanges addObject:[NSValue valueWithArticleRange:ArticleRangeMake(number, 0)]];
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
        NSUInteger index = [item.articleRanges indexOfObject:precedingRange];
        [item.articleRanges replaceObjectAtIndex:index withObject:newPrecedingRange];
    }

    if (followingRange)
    {
        NSUInteger index = [item.articleRanges indexOfObject:followingRange];
        if (newFollowingRange)
            [item.articleRanges replaceObjectAtIndex:index withObject:newFollowingRange];
        else
            [item.articleRanges removeObjectAtIndex:index];
    }

    changed = YES;
}

- (NSArray *)subscribedGroupNames
{
    NSMutableArray *groupNames = [[NSMutableArray alloc] init];
    for (NNNewsrcItem *item in _groups)
        if (item.subscribed)
            [groupNames addObject:item.groupName];
    return groupNames;
}

- (void)setSubscribedGroupNames:(NSArray *)groupNames
{
    NSMutableArray *groupNamesChecklist = [groupNames mutableCopy];
    for (NNNewsrcItem *item in _groups)
        if ([groupNamesChecklist containsObject:item.groupName])
        {
            item.subscribed = YES;
            [groupNamesChecklist removeObject:item.groupName];
        }
        else
            item.subscribed = NO;

    // Add any remaining checklist names, as they must be new
    for (NSString *name in groupNamesChecklist)
    {
        NNNewsrcItem *item = [[NNNewsrcItem alloc] init];
        item.groupName = name;
        item.articleRanges = [[NSMutableArray alloc] init];
        item.subscribed = YES;
        [_groups addObject:item];
        _groupsDictionary[item.groupName] = item;
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

        NNNewsrcItem *item = [[NNNewsrcItem alloc] init];
        item.groupName = [[NSString alloc] initWithBytes:buf
                                                  length:ptr - buf
                                                encoding:NSUTF8StringEncoding];
        item.articleRanges = [[NSMutableArray alloc] init];
        item.subscribed = (*ptr == ':');
        [_groups addObject:item];
        _groupsDictionary[item.groupName] = item;

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
                [item.articleRanges addObject:[NSValue valueWithArticleRange:range]];
            }
            else
            {
                long long n = atoll(buf);
                ArticleRange range = ArticleRangeMake(n, 0);
                [item.articleRanges addObject:[NSValue valueWithArticleRange:range]];
            }
        }
    }

    [stream close];
}

- (void)writeNewsrcFileAtURL:(NSURL *)url
{
    NSOutputStream *stream = [[NSOutputStream alloc] initWithURL:url append:NO];
    [stream open];
    for (NNNewsrcItem *item in _groups)
    {
        [stream write:(const uint8_t *)[item.groupName cStringUsingEncoding:NSUTF8StringEncoding]
            maxLength:[item.groupName length]];

        if (item.subscribed)
            [stream write:(const uint8_t *)": " maxLength:2];
        else
            [stream write:(const uint8_t *)"! " maxLength:2];

        BOOL comma = NO;
        for (NSValue *value in item.articleRanges)
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
