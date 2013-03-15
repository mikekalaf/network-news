//
//  GroupCoreDataStack.m
//  Network News
//
//  Created by David Schweinsberg on 6/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "GroupStore.h"

@interface GroupStore ()
{
    BOOL _articleRangeValid;
    ArticleRange _articleRange;
}

@end

@implementation GroupStore

- (id)initWithGroupName:(NSString *)groupName inDirectory:(NSString *)dirPath;
{
    self = [super initWithStoreName:groupName inDirectory:dirPath];
    if (self)
    {
    }
    return self;
}

//- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
//                               groupName:(NSString *)groupName
//                             inDirectory:(NSString *)dirPath
//{
//    self = [self initWithGroupName:groupName inDirectory:dirPath];
//    if (self)
//    {
//        [self setPersistentStoreCoordinator:
//    }
//    return self;
//}

- (NSString *)groupName
{
    return [self storeName];
}

- (ArticleRange)articleRange
{
//    if (_articleRangeValid)
//        return _articleRange;

    // Sort all the article parts and pick out the lowest and highest
    // article numbers
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"ArticlePart"
                                   inManagedObjectContext:[self managedObjectContext]]];
    [request setResultType:NSDictionaryResultType];
    [request setPropertiesToFetch:@[@"articleNumber"]];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"articleNumber" ascending:YES];
    [request setSortDescriptors:@[sortDescriptor]];

    NSError *error;
    NSArray *array = [[self managedObjectContext] executeFetchRequest:request error:&error];
    if (array && [array count] > 0)
    {
        NSDictionary *first = array[0];
        NSDictionary *last = [array lastObject];
        NSLog(@"%@ -> %@", first, last);

        uint64_t low = [first[@"articleNumber"] longLongValue];
        uint64_t high = [last[@"articleNumber"] longLongValue];
        _articleRange = ArticleRangeMake(low, high - low + 1);
        _articleRangeValid = YES;
    }

    return _articleRange;
}

- (GroupStore *)concurrentGroupStore
{
//    NSManagedObjectContext *context = [self managedObjectContext];

    // Create a new store with the same persistent store coordinator, but a
    // new managed object context
    GroupStore *groupStore = [[GroupStore alloc] initWithGroupName:[self groupName]
                                                       inDirectory:[self dirPath]];
    [groupStore setPersistentStoreCoordinator:[self persistentStoreCoordinator]];

//    // Do we really need to do this?
//    @try {
//        //[groupStore setManagedObjectContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType]];
//        [groupStore setManagedObjectContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType]];
//        [[groupStore managedObjectContext] setParentContext:context];
//    }
//    @catch (NSException *exception) {
//        NSLog(@"%@", exception);
//    }

    return groupStore;
}

@end
