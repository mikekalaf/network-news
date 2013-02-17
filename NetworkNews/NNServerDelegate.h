//
//  NNServerDelegate.h
//  Network News
//
//  Created by David Schweinsberg on 24/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NNServer;

@protocol NNServerDelegate

- (NSString *)userNameForServer:(NNServer *)aServer;

- (NSString *)passwordForServer:(NNServer *)aServer;

- (void)beginNetworkAccessForServer:(NNServer *)aServer;

- (void)endNetworkAccessForServer:(NNServer *)aServer;

@end
