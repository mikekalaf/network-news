//
//  main.m
//  NetworkNews
//
//  Created by David Schweinsberg on 17/02/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

void AlertViewFailedConnection(NSString *hostName)
{
    NSString *errorString = [NSString stringWithFormat:
                             @"The connection to the server \"%@\" failed.",
                             hostName];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cannot Get News"
                                                        message:errorString
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

void AlertViewFailedConnectionWithMessage(NSString *hostName, NSString *message)
{
    NSString *errorString = [NSString stringWithFormat:
                             @"The connection to the server \"%@\" failed with message \"%@\".",
                             hostName,
                             message];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cannot Get News"
                                                        message:errorString
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}
