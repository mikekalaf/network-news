//
//  Task.m
//  Network News
//
//  Created by David Schweinsberg on 12/12/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import "Task.h"
#import "NNServer.h"
#import "NNConnection.h"

NSString *TaskCompletedNotification = @"TaskCompletedNotification";
NSString *TaskErrorNotification = @"TaskErrorNotification";

@implementation Task

@synthesize connection;

- (id)initWithConnection:(NNConnection *)aConnection
{
    self = [super init];
    if (self)
    {
        connection = aConnection;
        
        // Look for the completion notification
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(bytesReceived:)
                   name:NNConnectionBytesReceivedNotification
                 object:connection];
        [nc addObserver:self
               selector:@selector(commandResponded:)
                   name:ServerCommandRespondedNotification
                 object:connection];
        [nc addObserver:self
               selector:@selector(authenticationFailed:)
                   name:ServerAuthenticationFailedNotification
                 object:connection];
        [nc addObserver:self
               selector:@selector(connectionError:)
                   name:ServerReadErrorNotification
                 object:connection];
        [nc addObserver:self
               selector:@selector(connectionDisconnected:)
                   name:ServerDisconnectedNotification
                 object:connection];
    }
    return self;
}

- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

- (void)start
{
}

- (void)cancel
{
    [connection disconnect];
}

- (void)bytesReceived:(NSNotification *)notification
{
}

- (void)commandResponded:(NSNotification *)notification
{
}

- (void)authenticationFailed:(NSNotification *)notification
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:TaskErrorNotification
                      object:self
                    userInfo:[notification userInfo]];
}

- (void)connectionError:(NSNotification *)notification
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:TaskErrorNotification
                      object:self
                    userInfo:[notification userInfo]];
}

- (void)connectionDisconnected:(NSNotification *)notification
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:TaskErrorNotification
                      object:self
                    userInfo:[notification userInfo]];
}

- (void)scheduleSelector:(SEL)aSelector
{
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop performSelector:aSelector
                      target:self
                    argument:nil
                       order:0
                       modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

@end
