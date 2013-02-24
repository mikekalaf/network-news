//
//  NNConnection.h
//  Network News
//
//  Created by David Schweinsberg on 23/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE == 1
#import <CFNetwork/CFNetwork.h>
#endif //TARGET_OS_IPHONE

extern NSString *NNConnectionBytesReceivedNotification;

@class NNServer;

@interface NNConnection : NSObject

@property(nonatomic, readonly) NNServer *server;

@property(nonatomic, copy, readonly) NSString *hostName;

@property(nonatomic, readonly) NSUInteger responseCode;

@property(nonatomic, retain, readonly) NSData *responseData;

- (id)initWithServer:(NNServer *)aServer;

- (void)connect;

- (void)disconnect;

- (void)writeData:(NSData *)data;

// NNTP Commands

- (void)articleWithMessageId:(NSString *)messageId;

- (void)bodyWithMessageId:(NSString *)messageId;

- (void)groupWithName:(NSString *)groupName;

- (void)help;

- (void)list;

- (void)listActiveWithWildmat:(NSString *)wildmat;

- (void)overWithRange:(NSRange)articleRange;

- (void)post;

@end
