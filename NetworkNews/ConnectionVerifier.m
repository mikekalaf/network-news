//
//  ConnectionVerifier.m
//  Network News
//
//  Created by David Schweinsberg on 16/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ConnectionVerifier.h"
#import "NNServer.h"
#import "NNConnection.h"
#import "NNServerDelegate.h"
#import "NewsAccount.h"

@interface ConnectionVerifier () <NNServerDelegate>
{
    NNServer *_server;
    NNConnection *_connection;
    NewsAccount *_account;
    void (^_completion)(BOOL connected, BOOL authenticated, BOOL verified);
}

@end


@implementation ConnectionVerifier

- (id)init
{
    self = [super init];
    if (self)
    {
    }
    return self;
}

- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];

    [_connection disconnect];

    _completion = nil;
    _server = nil;
}

- (void)verifyWithAccount:(NewsAccount *)account completion:(void (^)(BOOL, BOOL, BOOL))completion
{
    _account = account;
    _completion = completion;

    _server = [[NNServer alloc] initWithHostName:[account hostName] port:[account port]];
    [_server setSecure:[account isSecure]];
    [_server setDelegate:self];

    _connection = [[NNConnection alloc] initWithServer:_server];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(commandResponded:)
               name:ServerCommandRespondedNotification
             object:_connection];
    [nc addObserver:self
           selector:@selector(connectionError:)
               name:ServerReadErrorNotification
             object:_connection];
    [nc addObserver:self
           selector:@selector(authenticationFailed:)
               name:ServerAuthenticationFailedNotification
             object:_connection];

    // TODO This isn't so good.  The server may well return help prior to
    // any verification.  So we either need to explictly start any authentication,
    // or use some other command that will verify our connection
    [_connection help];
}

#pragma mark -
#pragma mark NNServerDelegate Methods

- (NSString *)userNameForServer:(NNServer *)aServer
{
    return [_account userName];
}

- (NSString *)passwordForServer:(NNServer *)aServer
{
    return [_account password];
}

- (void)beginNetworkAccessForServer:(NNServer *)aServer
{
//    UIApplication *app = [UIApplication sharedApplication];
//    app.networkActivityIndicatorVisible = YES;
}

- (void)endNetworkAccessForServer:(NNServer *)aServer
{
//    UIApplication *app = [UIApplication sharedApplication];
//    app.networkActivityIndicatorVisible = NO;
}

#pragma mark - Notifications

// TODO: Once we've reworked the NNTP connection to use blocks, create a more
// sensible scheme for passing info on the verification stages

- (void)commandResponded:(NSNotification *)notification
{
    if ([_connection responseCode] == 100)
        _completion(YES, YES, YES);
    else
        _completion(YES, NO, NO);
}

- (void)connectionError:(NSNotification *)notification
{
    _completion(NO, NO, NO);
}

- (void)authenticationFailed:(NSNotification *)notification
{
    _completion(YES, NO, NO);
}

@end
