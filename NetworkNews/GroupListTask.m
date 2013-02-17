//
//  GroupListTask.m
//  Network News
//
//  Created by David Schweinsberg on 12/12/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import "GroupListTask.h"
#import "NNConnection.h"
#import "LineIterator.h"
#import "GroupNode.h"

NSString *GroupListTaskCompletedNotification = @"GroupListTaskCompletedNotification";
NSString *GroupListTaskProgressNotification = @"GroupListTaskProgressNotification";

@implementation GroupListTask

@synthesize groupsRead;

- (id)initWithConnection:(NNConnection *)aConnection
    managedObjectContext:(NSManagedObjectContext *)aContext
{
    self = [super initWithConnection:aConnection];
    if (self)
    {
        context = aContext;

        // Core Data entity descriptions
        NSManagedObjectModel *model = context.persistentStoreCoordinator.managedObjectModel;
        groupNodeEntity = [[model entitiesByName] objectForKey:@"GroupNode"];

        linesRead = 0;
        groupsRead = 0;
    }
    return self;
}

- (void)start
{
    // Issue the command
    [connection list];
}

#pragma mark -
#pragma mark Notifications

- (void)bytesReceived:(NSNotification *)notification
{
    if (connection.responseCode == 215)
    {
        LineIterator *lineIterator = [[LineIterator alloc] initWithData:connection.responseData];
        NSMutableArray *groupsAdded = [[NSMutableArray alloc] initWithCapacity:1];
        
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

                GroupNode *groupNode = [[GroupNode alloc] initWithEntity:groupNodeEntity
                                          insertIntoManagedObjectContext:context];
                groupNode.name = [components objectAtIndex:0];
                
                // TODO Create the Group Node hierarchy
                
                [groupsAdded addObject:groupNode];
                
                ++groupsRead;
            }
            
            ++linesRead;
        }
        
        // Commit the changes to the store
        NSError *error = nil;
        if (![context save:&error])
        {
            NSLog(@"Error while saving\n%@",
                  ([error localizedDescription] != nil)
                  ? [error localizedDescription]
                  : @"Unknown Error");
        }
        
        // Turn groups into faults to manage our memory use
        for (GroupNode *groupNode in groupsAdded)
            [context refreshObject:groupNode mergeChanges:NO];
    }
    
    // Report progress
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:GroupListTaskProgressNotification object:self];
}

- (void)commandResponded:(NSNotification *)notification
{
    if (connection.responseCode == 215)
    {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:GroupListTaskCompletedNotification object:self];
    }
}

@end
