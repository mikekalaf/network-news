/*
 *  NetworkNews.h
 *  Network News
 *
 *  Created by David Schweinsberg on 11/04/10.
 *  Copyright 2010 David Schweinsberg. All rights reserved.
 *
 */

extern NSString *const ACCOUNTS_NAME_KEY;
extern NSString *const SERVICE_NAME_KEY;
extern NSString *const SUPPORT_URL_KEY;
extern NSString *const HOSTNAME_KEY;
extern NSString *const PORT_KEY;
extern NSString *const SECURE_KEY;
extern NSString *const USERNAME_KEY;
extern NSString *const PASSWORD_KEY;
//extern NSString *const DESCRIPTION_KEY;
extern NSString *const MAX_ARTICLE_COUNT_KEY;
extern NSString *const DELETE_AFTER_DAYS_KEY;
extern NSString *const MOST_RECENT_GROUP_SEARCH;
extern NSString *const MOST_RECENT_GROUP_SEARCH_SCOPE;
extern NSString *const MOST_RECENT_ARTICLE_SEARCH;
extern NSString *const MOST_RECENT_ARTICLE_SEARCH_SCOPE;

void AlertViewFailedConnection(NSString *hostName);
void AlertViewFailedConnectionWithMessage(NSString *hostName, NSString *message);
