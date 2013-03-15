//
//  GroupCoreDataStack.h
//  Network News
//
//  Created by David Schweinsberg on 6/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "CoreDataStore.h"
#import "ArticleRange.h"

@class Group;

@interface GroupStore : CoreDataStore

@property (nonatomic, readonly) NSString *groupName;
@property (nonatomic, readonly) ArticleRange articleRange;

- (id)initWithGroupName:(NSString *)groupName inDirectory:(NSString *)dirPath;

- (GroupStore *)concurrentGroupStore;

@end
