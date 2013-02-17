//
//  Task.h
//  Network News
//
//  Created by David Schweinsberg on 12/12/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *TaskCompletedNotification;
extern NSString *TaskErrorNotification;

@class NNConnection;

@interface Task : NSObject
{
    NNConnection *connection;
}

@property (retain) NNConnection *connection;

- (id)initWithConnection:(NNConnection *)aConnection;

- (void)start;

- (void)cancel;

- (void)bytesReceived:(NSNotification *)notification;

- (void)commandResponded:(NSNotification *)notification;

- (void)authenticationFailed:(NSNotification *)notification;

- (void)connectionError:(NSNotification *)notification;

- (void)connectionDisconnected:(NSNotification *)notification;

- (void)scheduleSelector:(SEL)aSelector;

@end
