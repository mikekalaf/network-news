//
//  GroupCoreDataStack.h
//  Network News
//
//  Created by David Schweinsberg on 6/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "CoreDataStack.h"

@class Group;

@interface GroupCoreDataStack : CoreDataStack
{
    Group *group;
}

@property(retain, readonly) Group *group;

- (id)initWithGroupName:(NSString *)aGroupName inDirectory:(NSString *)aDirPath;

@end
