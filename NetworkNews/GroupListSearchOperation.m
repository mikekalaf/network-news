//
//  GroupListSearchOperation.m
//  NetworkNews
//
//  Created by David Schweinsberg on 9/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "GroupListSearchOperation.h"
#import "NewsConnection.h"
#import "NewsResponse.h"
#import "NewsConnectionPool.h"
#import "LineIterator.h"
#import "GroupListing.h"

@interface GroupListSearchOperation ()
{
    NewsConnectionPool *_connectionPool;
}

@end


@implementation GroupListSearchOperation

- (id)initWithConnectionPool:(NewsConnectionPool *)connectionPool wildmat:(NSString *)wildmat
{
    self = [super init];
    if (self)
    {
        _connectionPool = connectionPool;
        _wildmat = wildmat;
    }
    return self;
}

- (void)main
{
    @try
    {
        BOOL retry = NO;
        do
        {
            NewsConnection *newsConnection = [_connectionPool dequeueConnection];
            NewsResponse *response = [newsConnection listActiveWithWildmat:_wildmat];

            if ([response statusCode] == 215)
            {
                NSMutableArray *groups = [[NSMutableArray alloc] initWithCapacity:1];
                NSUInteger linesRead = 0;

                LineIterator *lineIterator = [[LineIterator alloc] initWithData:[response data]];

                while (!lineIterator.isAtEnd)
                {
                    NSString *line = [lineIterator nextLine];

                    // Is this the end of the list?
                    if (lineIterator.isAtEnd && [line isEqualToString:@".\r\n"])
                        break;

                    // Extract the group name from the line
                    if (linesRead > 0)
                    {
                        NSArray *components = [line componentsSeparatedByCharactersInSet:
                                               [NSCharacterSet whitespaceCharacterSet]];

                        GroupListing *group = [[GroupListing alloc] initWithName:components[0]
                                                                  highestArticle:[components[1] longLongValue]
                                                                   lowestArticle:[components[2] longLongValue]
                                                                   postingStatus:[components[3] characterAtIndex:0]];
                        [groups addObject:group];
                    }

                    ++linesRead;
                }
                _groups = groups;

                retry = NO;
            }
            else if ([response statusCode] == 503)
            {
                // Connection has probably timed-out, so retry with a
                // new connection (if we haven't retried already)
                newsConnection = nil;
                retry = !retry;
            }
            else
            {
                NSLog(@"STATUS CODE: %d", [response statusCode]);
                NSLog(@"%@", [[NSString alloc] initWithData:[response data] encoding:NSUTF8StringEncoding]);

                retry = NO;
            }

            [_connectionPool enqueueConnection:newsConnection];
        } while (retry);
    }
    @catch (NSException *exception)
    {
    }
    @finally
    {
    }
}

@end
