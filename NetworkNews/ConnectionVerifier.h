//
//  ConnectionVerifier.h
//  Network News
//
//  Created by David Schweinsberg on 16/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NewsAccount;

@interface ConnectionVerifier : NSObject

+ (void)verifyWithAccount:(NewsAccount *)account
               completion:(void (^)(BOOL connected, BOOL authenticated,
                                    BOOL verified))completion;

@end
