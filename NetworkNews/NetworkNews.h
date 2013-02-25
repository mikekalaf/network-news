/*
 *  NetworkNews.h
 *  Network News
 *
 *  Created by David Schweinsberg on 11/04/10.
 *  Copyright 2010 David Schweinsberg. All rights reserved.
 *
 */

#define HOST_KEY                            @"Host"
#define PORT_KEY                            @"Port"
#define SECURE_KEY                          @"Secure"
#define USERNAME_KEY                        @"UserName"
#define PASSWORD_KEY                        @"Password"
#define DESCRIPTION_KEY                     @"Description"
#define MAX_ARTICLE_COUNT_KEY               @"MaxArticleCount"
#define DELETE_AFTER_DAYS_KEY               @"DeleteAfterDays"
#define MOST_RECENT_GROUP_SEARCH            @"MostRecentGroupSearch"
#define MOST_RECENT_GROUP_SEARCH_SCOPE      @"MostRecentGroupSearchScope"
#define MOST_RECENT_ARTICLE_SEARCH          @"MostRecentArticleSearch"
#define MOST_RECENT_ARTICLE_SEARCH_SCOPE    @"MostRecentArticleSearchScope"

void AlertViewFailedConnection(NSString *hostName);
void AlertViewFailedConnectionWithMessage(NSString *hostName, NSString *message);
