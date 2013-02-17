//
//  GroupListSearchTask.m
//  Network News
//
//  Created by David Schweinsberg on 24/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "GroupListSearchTask.h"
#import "NNConnection.h"
#import "LineIterator.h"

NSString *GroupListSearchTaskCompletedNotification = @"GroupListSearchTaskCompletedNotification";
NSString *GroupListSearchTaskProgressNotification = @"GroupListSearchTaskProgressNotification";

@implementation GroupListInfo

@synthesize name;
@synthesize high;
@synthesize low;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.name = [aDecoder decodeObjectForKey:@"Name"];
        high = [aDecoder decodeInt64ForKey:@"High"];
        low = [aDecoder decodeInt64ForKey:@"Low"];
    }
    return self;
}

- (long long)count
{
    return high - low + 1;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:name forKey:@"Name"];
    [aCoder encodeInt64:high forKey:@"High"];
    [aCoder encodeInt64:low forKey:@"Low"];
}

@end

@implementation GroupListSearchTask

@synthesize groupList;

- (id)initWithConnection:(NNConnection *)aConnection
                 wildmat:(NSString *)aWildmat
{
    self = [super initWithConnection:aConnection];
    if (self)
    {
        wildmat = [aWildmat copy];
        groupList = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return self;
}

- (void)start
{
    // Issue the command
    [connection listActiveWithWildmat:wildmat];
}

#pragma mark -
#pragma mark Notifications

- (void)bytesReceived:(NSNotification *)notification
{
    if (connection.responseCode == 215)
    {
//        NSLog(@"GroupListSearchTask bytesReceived:");

        LineIterator *lineIterator = [[LineIterator alloc] initWithData:connection.responseData];
        
        while (!lineIterator.isAtEnd)
        {
            NSString *line = [lineIterator nextLine];
            if (lineIterator.partial)
            {
                // We have a partial line, so store it, and then leave this loop
                if (!partialLine)
                    partialLine = [[NSMutableString alloc] initWithString:line];
                else
                    [partialLine appendString:line];
                break;
            }
            
            // If we have a partial line from a previous run, form a complete
            // line with the newly retrieved line fragment
            if (partialLine)
            {
                [partialLine appendString:line];
                line = partialLine;
                partialLine = nil;
            }
            
            // Is this the end of the list?
            if (lineIterator.isAtEnd && [line isEqualToString:@".\r\n"])
                break;
            
            // Extract the group name from the line
            if (linesRead > 0)
            {
                NSArray *components = [line componentsSeparatedByCharactersInSet:
                                       [NSCharacterSet whitespaceCharacterSet]];
                
                GroupListInfo *listInfo = [[GroupListInfo alloc] init];
                listInfo.name = [components objectAtIndex:0];
                listInfo.high = [[components objectAtIndex:1] longLongValue];
                listInfo.low = [[components objectAtIndex:2] longLongValue];
                
                [groupList addObject:listInfo];

//                NSLog(@"Group: %@", [components objectAtIndex:0]);
            }
            
            ++linesRead;
        }
    }
    
    // Report progress
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:GroupListSearchTaskProgressNotification object:self];
}

- (void)commandResponded:(NSNotification *)notification
{
    if (connection.responseCode == 215)
    {
//        NSLog(@"GroupListSearchTask commandResponded:");

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:GroupListSearchTaskCompletedNotification object:self];
    }
}

@end
