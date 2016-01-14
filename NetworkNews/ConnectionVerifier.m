//
//  ConnectionVerifier.m
//  Network News
//
//  Created by David Schweinsberg on 16/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ConnectionVerifier.h"
#import "NewsAccount.h"
#import "NewsConnection.h"
#import "NewsResponse.h"

@implementation ConnectionVerifier

+ (void)verifyWithAccount:(NewsAccount *)account completion:(void (^)(BOOL, BOOL, BOOL))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL connected = NO;
        BOOL authenticated = NO;
        BOOL verified = NO;
        NewsConnection *connection = [[NewsConnection alloc] initWithHost:account.hostName
                                                                     port:account.port
                                                                 isSecure:account.secure];
        if (connection)
        {
            connected = YES;

            if (account.userName)
            {
                NSUInteger statusCode = [connection loginWithUser:account.userName
                                                         password:account.password];
                if (statusCode == 281)
                    authenticated = YES;
            }
            else
            {
                authenticated = YES;
            }

            NewsResponse *response = [connection help];
            if (response.statusCode == 100)
                verified = YES;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(connected, authenticated, verified);
        });
    });
}

@end
