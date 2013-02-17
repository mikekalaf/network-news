//
//  GroupListSearchTask.h
//  Network News
//
//  Created by David Schweinsberg on 24/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "Task.h"

extern NSString *GroupListSearchTaskCompletedNotification;
extern NSString *GroupListSearchTaskProgressNotification;

@interface GroupListSearchTask : Task
{
    NSString *wildmat;
    NSMutableString *partialLine;
    NSMutableArray *groupList;
    NSUInteger linesRead;
}

@property(retain, readonly) NSArray *groupList;

- (id)initWithConnection:(NNConnection *)aConnection
                 wildmat:(NSString *)aWildmat;

@end


@interface GroupListInfo : NSObject <NSCoding>
{
    NSString *name;
    long long high;
    long long low;
}

@property(nonatomic, copy) NSString *name;
@property(nonatomic) long long high;
@property(nonatomic) long long low;
@property(nonatomic, readonly) long long count;

@end
