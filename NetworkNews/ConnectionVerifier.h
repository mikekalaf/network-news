//
//  ConnectionVerifier.h
//  Network News
//
//  Created by David Schweinsberg on 16/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NNServerDelegate.h"

@class NNServer;
@class NNConnection;
@class ConnectionVerifier;

@protocol ConnectionVerifierDelegate

- (void)connectionVerifier:(ConnectionVerifier *)verifier verified:(BOOL)verified;

@end


@interface ConnectionVerifier : NSObject <NNServerDelegate>

@property(nonatomic, readonly) BOOL serverConnectionSuccess;
@property(nonatomic, readonly) BOOL authenticationSuccess;

- (id)initWithHostName:(NSString *)aHostName
                  port:(NSUInteger)port
                secure:(BOOL)secure
              userName:(NSString *)aUserName
              password:(NSString *)aPassword
              delegate:(id <ConnectionVerifierDelegate>)aDelegate;

- (void)verify;

@end
