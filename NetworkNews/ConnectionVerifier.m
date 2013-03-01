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

@interface ConnectionVerifier ()
{
    NNServer *_server;
    NNConnection *connection;
    NSString *userName;
    NSString *password;
    id <ConnectionVerifierDelegate> delegate;
}

@end


@implementation ConnectionVerifier

- (id)initWithHostName:(NSString *)aHostName
                  port:(NSUInteger)port
                secure:(BOOL)secure
              userName:(NSString *)aUserName
              password:(NSString *)aPassword
              delegate:(id <ConnectionVerifierDelegate>)aDelegate
{
    self = [super init];
    if (self)
    {
        _server = [[NNServer alloc] initWithHostName:aHostName port:port];
        [_server setSecure:secure];
        [_server setDelegate:self];
        
        connection = [[NNConnection alloc] initWithServer:_server];

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(commandResponded:)
                   name:ServerCommandRespondedNotification
                 object:connection];
        [nc addObserver:self
               selector:@selector(connectionError:)
                   name:ServerReadErrorNotification
                 object:connection];
        [nc addObserver:self
               selector:@selector(authenticationFailed:)
                   name:ServerAuthenticationFailedNotification
                 object:connection];
        
        userName = [aUserName copy];
        password = [aPassword copy];
        delegate = aDelegate;
    }
    return self;
}

- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];

    [connection disconnect];
}

- (void)verify
{
    // TODO This isn't so good.  The server may well return help prior to
    // any verification.  So we either need to explictly start any authentication,
    // or use some other command that will verify our connection
    [connection help];
}

#pragma mark -
#pragma mark NNServerDelegate Methods

- (NSString *)userNameForServer:(NNServer *)aServer
{
    return userName;
}

- (NSString *)passwordForServer:(NNServer *)aServer
{
    return password;
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

#pragma mark -
#pragma mark Notifications

- (void)commandResponded:(NSNotification *)notification
{
    _serverConnectionSuccess = YES;

//    if (connection.responseCode == 281)
    if (connection.responseCode == 100)
    {
        _authenticationSuccess = YES;
        [delegate connectionVerifier:self verified:YES];
    }
    else
    {
        _authenticationSuccess = NO;
        [delegate connectionVerifier:self verified:NO];
    }
}

- (void)connectionError:(NSNotification *)notification
{
    _serverConnectionSuccess = NO;
    _authenticationSuccess = NO;
    [delegate connectionVerifier:self verified:NO];
}

- (void)authenticationFailed:(NSNotification *)notification
{
    _authenticationSuccess = NO;
    [delegate connectionVerifier:self verified:NO];
}

@end
