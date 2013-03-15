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
@property(nonatomic, readonly) NSDate *lastSaveDate;
@property(nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property(nonatomic) NSManagedObjectModel *managedObjectModel;
@property(nonatomic) NSManagedObjectContext *managedObjectContext;

- (id)initWithStoreName:(NSString *)aStoreName inDirectory:(NSString *)aDirPath;

//- (CoreDataStore *)concurrentStore;

- (void)save;

@end
