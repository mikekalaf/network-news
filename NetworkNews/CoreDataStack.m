//
//  CoreDataStack.m
//  Network News
//
//  Created by David Schweinsberg on 22/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "CoreDataStack.h"


@implementation CoreDataStack

@synthesize storeName;

- (id)initWithStoreName:(NSString *)aStoreName inDirectory:(NSString *)aDirPath
{
    self = [super init];
    if (self)
    {
        storeName = [aStoreName copy];
        dirPath = [aDirPath copy];
    }
    return self;
}

- (NSString *)applicationSupportDirectory
{
#if TARGET_OS_IPHONE == 1
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    return [paths lastObject];
#elif TARGET_OS_MAC == 1
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Network News"];
#endif
}

/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel)
        return managedObjectModel;
	
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The directory for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator)
        return persistentStoreCoordinator;
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom)
    {
        NSAssert(NO, @"Managed object model is nil");
        //NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSString *path;
    if (dirPath)
        path = [applicationSupportDirectory stringByAppendingPathComponent:dirPath];
    else
        path = applicationSupportDirectory;
    NSError *error = nil;
    
    if (![fileManager fileExistsAtPath:path isDirectory:NULL])
    {
		if (![fileManager createDirectoryAtPath:path
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:&error])
        {
            NSAssert(NO, ([NSString stringWithFormat:
                           @"Failed to create App Support directory %@ : %@",
                           path,
                           error]));
            NSLog(@"Error creating application support directory at %@ : %@",
                  path,
                  error);
            return nil;
		}
    }
    NSString *storeNameWithExt = [storeName stringByAppendingPathExtension:@"db"];
    NSURL *url = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:storeNameWithExt]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
                                                  configuration:nil 
                                                            URL:url 
                                                        options:nil 
                                                          error:&error])
    {
#if TARGET_OS_IPHONE == 1
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
#elif TARGET_OS_MAC == 1
        [[NSApplication sharedApplication] presentError:error];
        [persistentStoreCoordinator release];
        persistentStoreCoordinator = nil;
        return nil;
#endif
    }    
    
    return persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */

- (NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext)
        return managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store"
                forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file."
                forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN"
                                             code:9999
                                         userInfo:dict];
#if TARGET_OS_IPHONE == 1
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
#elif TARGET_OS_MAC == 1
        [[NSApplication sharedApplication] presentError:error];
        return nil;
#endif
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    // We don't want the undo manager
    [managedObjectContext setUndoManager:nil];
    
    return managedObjectContext;
}

- (void)save
{
    NSError *error = nil;
    if (![self.managedObjectContext save:&error])
    {
        NSLog(@"Error while saving\n%@",
              ([error localizedDescription] != nil)
              ? [error localizedDescription]
              : @"Unknown Error");
    }
}

@end
