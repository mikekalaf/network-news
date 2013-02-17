//
//  NNServer.m
//  Network News
//
//  Created by David Schweinsberg on 24/11/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import "NNServer.h"

NSString *ServerReadOpenCompletedNotification = @"ServerReadOpenCompletedNotification";
NSString *ServerWriteOpenCompletedNotification = @"ServerWriteOpenCompletedNotification";
NSString *ServerConnectedNotification = @"ServerConnectedNotification";
NSString *ServerAuthenticatedNotification = @"ServerAuthenticatedNotification";
NSString *ServerAuthenticationFailedNotification = @"ServerAuthenticationFailedNotification";
NSString *ServerDisconnectedNotification = @"ServerDisconnectedNotification";
NSString *ServerReadErrorNotification = @"ServerReadErrorNotification";
NSString *ServerWriteErrorNotification = @"ServerWriteErrorNotification";
NSString *ServerCommandRespondedNotification = @"ServerCommandRespondedNotification";

static void HostClientCallBack(CFHostRef theHost,
                               CFHostInfoType typeInfo,
                               const CFStreamError *error,
                               void *info)
{
//    [(NNServer *)info resolvedAddress];
}

@implementation NNServer

- (id)initWithHostName:(NSString *)aHostName port:(NSUInteger)aPort
{
    self = [super init];
    if (self)
    {
        _hostName = [aHostName copy];
        _port = aPort;
        _host = CFHostCreateWithName(kCFAllocatorDefault,
                                    (__bridge CFStringRef)_hostName);
        
        CFHostClientContext context = { 0, (__bridge void *)self, NULL, NULL, NULL };
        CFHostSetClient(_host, HostClientCallBack, &context);
        
        CFHostScheduleWithRunLoop(_host,
                                  CFRunLoopGetCurrent(),
                                  kCFRunLoopCommonModes);
        
        CFStreamError error;
        if (CFHostStartInfoResolution(_host,
                                      kCFHostAddresses,
                                      &error) == false)
        {
        }
    }
    return self;
}

- (void)dealloc
{
    CFHostUnscheduleFromRunLoop(_host,
                                CFRunLoopGetCurrent(),
                                kCFRunLoopCommonModes);
    CFHostSetClient(_host, NULL, NULL);
}

#pragma mark -
#pragma mark Private Methods

- (void)resolvedAddress
{
//    [self connect];
}

@end
