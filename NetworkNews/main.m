//
//  main.m
//  NetworkNews
//
//  Created by David Schweinsberg on 17/02/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

NSString *const ACCOUNTS_NAME_KEY = @"Accounts";
NSString *const SERVICE_NAME_KEY = @"ServiceName";
NSString *const SUPPORT_URL_KEY = @"SupportURL";
NSString *const HOSTNAME_KEY = @"HostName";
NSString *const PORT_KEY = @"Port";
NSString *const SECURE_KEY = @"Secure";
NSString *const USERNAME_KEY = @"UserName";
NSString *const PASSWORD_KEY = @"Password";
//NSString *const DESCRIPTION_KEY = @"Description";
NSString *const MAX_ARTICLE_COUNT_KEY = @"MaxArticleCount";
NSString *const DELETE_AFTER_DAYS_KEY = @"DeleteAfterDays";
NSString *const MOST_RECENT_GROUP_SEARCH = @"MostRecentGroupSearch";
NSString *const MOST_RECENT_GROUP_SEARCH_SCOPE = @"MostRecentGroupSearchScope";
NSString *const MOST_RECENT_ARTICLE_SEARCH = @"MostRecentArticleSearch";
NSString *const MOST_RECENT_ARTICLE_SEARCH_SCOPE = @"MostRecentArticleSearchScope";

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
