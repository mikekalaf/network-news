//
//  GroupCoreDataStack.m
//  Network News
//
//  Created by David Schweinsberg on 6/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "GroupCoreDataStack.h"
#import "Group.h"

@implementation GroupCoreDataStack

@synthesize group;

- (id)initWithGroupName:(NSString *)aGroupName inDirectory:(NSString *)aDirPath
{
    self = [super initWithStoreName:aGroupName inDirectory:aDirPath];
    if (self)
    {
        // Get Group information
        NSEntityDescription *groupEntity = [[self.managedObjectModel entitiesByName] objectForKey:@"Group"];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:groupEntity];
        
        NSError *error;
        NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
        if (array == nil)
        {
            // Deal with error...
        }
        
        if (array.count == 0)
        {
            // Create the group
            group = [[Group alloc] initWithEntity:groupEntity
                   insertIntoManagedObjectContext:self.managedObjectContext];
            group.name = aGroupName;
        }
        else
        {
            group = [array objectAtIndex:0];
        }
    }
    return self;
}

@end
