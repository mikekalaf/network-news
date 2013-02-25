//
//  NNServer.h
//  Network News
//
//  Created by David Schweinsberg on 24/11/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE == 1
#import <CFNetwork/CFNetwork.h>
#endif //TARGET_OS_IPHONE
#import "NNServerDelegate.h"

extern NSString *ServerReadOpenCompletedNotification;
extern NSString *ServerWriteOpenCompletedNotification;
extern NSString *ServerConnectedNotification;
extern NSString *ServerAuthenticatedNotification;
extern NSString *ServerAuthenticationFailedNotification;
extern NSString *ServerDisconnectedNotification;
extern NSString *ServerReadErrorNotification;
extern NSString *ServerWriteErrorNotification;
extern NSString *ServerCommandRespondedNotification;

@interface NNServer : NSObject

@property(nonatomic, copy, readonly) NSString *hostName;
@property(nonatomic, readonly) NSUInteger port;
@property(nonatomic, readonly) CFHostRef host;
@property(nonatomic, getter = isSecure) BOOL secure;
@property(nonatomic, weak) id <NNServerDelegate> delegate;

- (id)initWithHostName:(NSString *)aHostName port:(NSUInteger)aPort;

@end
