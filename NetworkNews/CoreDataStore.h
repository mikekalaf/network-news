//
//  CoreDataStore.h
//  Network News
//
//  Created by David Schweinsberg on 22/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface CoreDataStore : NSObject

@property(nonatomic, readonly) NSString *storeName;
@property(nonatomic, readonly) NSString *dirPath;
@property(nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property(nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property(nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

- (id)initWithStoreName:(NSString *)aStoreName inDirectory:(NSString *)aDirPath;

-        (id)initWithStoreName:(NSString *)aStoreName
                   inDirectory:(NSString *)aDirPath
withPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;

- (void)save;

@end
