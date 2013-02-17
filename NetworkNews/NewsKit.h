/*
 *  NewsKit.h
 *  Network News
 *
 *  Created by David Schweinsberg on 12/02/10.
 *  Copyright 2010 David Schweinsberg. All rights reserved.
 *
 */

#define APP_NAME_TOKEN @"NetworkNews"

#if TARGET_OS_IPHONE == 1
    #define OS_NAME @"iPhone OS"
#elif TARGET_OS_MAC == 1
    #define OS_NAME @"Mac OS X"
#endif