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

- (NSString *)groupName
{
    return self.storeName;
}

- (ArticleRange)articleRange
{
//    if (_articleRangeValid)
//        return _articleRange;

    // Sort all the article parts and pick out the lowest and highest
    // article numbers
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"ArticlePart"
                                   inManagedObjectContext:self.managedObjectContext];
    request.resultType = NSDictionaryResultType;
    request.propertiesToFetch = @[@"articleNumber"];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"articleNumber" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];

    NSError *error;
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (array && array.count > 0)
    {
        NSDictionary *first = array[0];
        NSDictionary *last = array.lastObject;
        NSLog(@"%@ -> %@", first, last);

        uint64_t low = [first[@"articleNumber"] longLongValue];
        uint64_t high = [last[@"articleNumber"] longLongValue];
        _articleRange = ArticleRangeMake(low, high - low + 1);
        _articleRangeValid = YES;
    }

    return _articleRange;
}

- (NSDate *)lastUpdate
{
    NSManagedObject *group = [self group];
    return [group valueForKey:@"lastUpdate"];
}

- (GroupStore *)concurrentGroupStore
{
    // Create a new store with the same persistent store coordinator, but a
    // new managed object context
    GroupStore *groupStore = [[GroupStore alloc] initWithStoreName:self.groupName
                                                       inDirectory:self.dirPath
                                    withPersistentStoreCoordinator:self.persistentStoreCoordinator
                                                      isMainThread:NO];

    return groupStore;
}

- (void)save
{
    NSManagedObject *group = [self group];
    [group setValue:[NSDate date] forKey:@"lastUpdate"];

    [super save];
}

- (NSManagedObject *)group
{
    NSEntityDescription *groupEntity = [NSEntityDescription entityForName:@"Group"
                                                   inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = groupEntity;

    NSError *error;
    NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (array.count > 0)
    {
        return array.lastObject;
    }
    else
    {
        return [[NSManagedObject alloc] initWithEntity:groupEntity
                        insertIntoManagedObjectContext:self.managedObjectContext];
    }
}

@end
