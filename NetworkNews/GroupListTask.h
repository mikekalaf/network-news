//
//  GroupListTask.h
//  Network News
//
//  Created by David Schweinsberg on 12/12/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import "Task.h"
#import <CoreData/CoreData.h>

extern NSString *GroupListTaskCompletedNotification;
extern NSString *GroupListTaskProgressNotification;

@interface GroupListTask : Task
{
    NSManagedObjectContext *context;
    NSEntityDescription *groupNodeEntity;
    NSMutableString *partialLine;
    NSUInteger linesRead;
    NSUInteger groupsRead;
}

@property(readonly) NSUInteger groupsRead;

- (id)initWithConnection:(NNConnection *)aConnection
    managedObjectContext:(NSManagedObjectContext *)aContext;

@end
