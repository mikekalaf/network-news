//
//  CoreDataStore.m
//  Network News
//
//  Created by David Schweinsberg on 22/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "CoreDataStore.h"

@interface CoreDataStore () {
  NSManagedObjectModel *_managedObjectModel;
  NSManagedObjectContext *_managedObjectContext;
  BOOL _isMainThread;
}

@end

@implementation CoreDataStore

- (instancetype)initWithStoreName:(NSString *)aStoreName
                       inDirectory:(NSString *)aDirPath
    withPersistentStoreCoordinator:
        (NSPersistentStoreCoordinator *)persistentStoreCoordinator
                      isMainThread:(BOOL)isMainThread {
  self = [super init];
  if (self) {
    _storeName = [aStoreName copy];
    _dirPath = [aDirPath copy];
    _persistentStoreCoordinator = persistentStoreCoordinator;
    _isMainThread = isMainThread;
    if (persistentStoreCoordinator == nil) {
      [self initPersistentStoreCoordinator];
    }
  }
  return self;
}

- (instancetype)initWithStoreName:(NSString *)aStoreName
                      inDirectory:(NSString *)aDirPath {
  return [self initWithStoreName:aStoreName
                         inDirectory:aDirPath
      withPersistentStoreCoordinator:nil
                        isMainThread:YES];
}

- (NSURL *)applicationDocumentsDirectory {
  return [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                inDomains:NSUserDomainMask]
      .lastObject;
}

- (NSManagedObjectModel *)managedObjectModel {
  if (_managedObjectModel)
    return _managedObjectModel;
  NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"News"
                                            withExtension:@"momd"];
  _managedObjectModel =
      [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
  return _managedObjectModel;
}

- (void)initPersistentStoreCoordinator {
  // Build up the store URL, ensuring that the containing directory exists
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSURL *applicationDocumentsDirectory = [self applicationDocumentsDirectory];
  NSURL *storeURL;
  if (_dirPath)
    storeURL =
        [applicationDocumentsDirectory URLByAppendingPathComponent:_dirPath];
  else
    storeURL = applicationDocumentsDirectory;
  NSError *error = nil;

  if (![fileManager fileExistsAtPath:storeURL.path isDirectory:NULL]) {
    if (![fileManager createDirectoryAtURL:storeURL
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error]) {
      NSAssert(NO,
               ([NSString stringWithFormat:
                              @"Failed to create App Support directory %@ : %@",
                              storeURL, error]));
      NSLog(@"Error creating application support directory at %@ : %@",
            storeURL, error);
      return;
    }
  }

  //    NSString *storeNameWithExt = [_storeName
  //    stringByAppendingPathExtension:@"sqlite"]; NSURL *url = [storeURL
  //    URLByAppendingPathComponent:storeNameWithExt];

  // Create the store
  _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
      initWithManagedObjectModel:self.managedObjectModel];
  //    if (![_persistentStoreCoordinator
  //    addPersistentStoreWithType:NSSQLiteStoreType
  //                                                  configuration:nil
  //                                                            URL:url
  //                                                        options:nil
  //                                                          error:&error])
  if (![_persistentStoreCoordinator
          addPersistentStoreWithType:NSInMemoryStoreType
                       configuration:nil
                                 URL:nil
                             options:nil
                               error:&error]) {
    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
    abort();
  }
}

- (NSManagedObjectContext *)managedObjectContext {
  if (_managedObjectContext)
    return _managedObjectContext;

  NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
  if (coordinator != nil) {
    if (_isMainThread)
      _managedObjectContext = [[NSManagedObjectContext alloc]
          initWithConcurrencyType:NSMainQueueConcurrencyType];
    else
      _managedObjectContext = [[NSManagedObjectContext alloc]
          initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    _managedObjectContext.persistentStoreCoordinator = coordinator;
  }
  return _managedObjectContext;
}

- (void)save {
  NSError *error = nil;
  [_managedObjectContext save:&error];

  if (error == nil) {
    //_lastSaveDate = [NSDate date];
  } else {
    NSLog(@"Error while saving: %@", error);
  }
}

@end
