//
//  CoreDataStack.h
//  Network News
//
//  Created by David Schweinsberg on 22/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface CoreDataStack : NSObject
{
    NSString *storeName;
    NSString *dirPath;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}

@property(nonatomic, retain, readonly) NSString *storeName;
@property(nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property(nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property(nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (id)initWithStoreName:(NSString *)aStoreName inDirectory:(NSString *)aDirPath;

- (void)save;

@end
