//
//  CoreDataStore.m
//  Network News
//
//  Created by David Schweinsberg on 22/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "CoreDataStore.h"


@interface CoreDataStore ()
//{
//    NSString *_dirPath;
//    NSManagedObjectModel *_managedObjectModel;
//    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
//    NSManagedObjectContext *_managedObjectContext;
//}

@end


@implementation CoreDataStore

- (id)initWithStoreName:(NSString *)aStoreName inDirectory:(NSString *)aDirPath
{
    self = [super init];
    if (self)
    {
        _storeName = [aStoreName copy];
        _dirPath = [aDirPath copy];
    }
    return self;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

//- (CoreDataStore *)concurrentStore
//{
//    // Create a new store with the same persistent store coordinator, but a
//    // new managed object context
//    CoreDataStore *coreDataStore = [[[self class] alloc] initWithStoreName:_storeName
//                                                                inDirectory:_dirPath];
//    [coreDataStore setPersistentStoreCoordinator:_persistentStoreCoordinator];
//
//    [coreDataStore setManagedObjectContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType]];
//    [[coreDataStore managedObjectContext] setParentContext:_managedObjectContext];
//
//    return coreDataStore;
//}

/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel)
        return _managedObjectModel;
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"News" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The directory for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator)
        return _persistentStoreCoordinator;

    // Build up the store URL, ensuring that the containing directory exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationDocumentsDirectory = [self applicationDocumentsDirectory];
    NSURL *storeURL;
    if (_dirPath)
        storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent:_dirPath];
    else
        storeURL = applicationDocumentsDirectory;
    NSError *error = nil;
    
    if (![fileManager fileExistsAtPath:[storeURL path] isDirectory:NULL])
    {
		if (![fileManager createDirectoryAtURL:storeURL
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&error])
        {
            NSAssert(NO, ([NSString stringWithFormat:
                           @"Failed to create App Support directory %@ : %@",
                           storeURL,
                           error]));
            NSLog(@"Error creating application support directory at %@ : %@",
                  storeURL,
                  error);
            return nil;
		}
    }

    NSString *storeNameWithExt = [_storeName stringByAppendingPathExtension:@"sqlite"];
    NSURL *url = [storeURL URLByAppendingPathComponent:storeNameWithExt];

    // Create the store
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil 
                                                            URL:url 
                                                        options:nil 
                                                          error:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

//- (void)setPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
//{
//    _persistentStoreCoordinator = persistentStoreCoordinator;
//}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext)
        return _managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

//- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
//{
//    _managedObjectContext = managedObjectContext;
//}

- (void)save
{
    NSError *error = nil;
    [_managedObjectContext save:&error];

    if (error == nil)
    {
        _lastSaveDate = [NSDate date];
    }
    else
    {
        NSLog(@"Error while saving: %@", error);
    }
}

@end
