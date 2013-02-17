//
//  NNConnection.m
//  Network News
//
//  Created by David Schweinsberg on 23/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NNConnection.h"
#import "NNServer.h"

#define BUFSIZE     65536

// NOTE When adding commands with multiline responses, be sure to add the
// response code into the "isMultilineResponse" method

#define ARTICLE_COMMAND         @"ARTICLE"
#define AUTHINFO_USER_COMMAND   @"AUTHINFO USER"
#define AUTHINFO_PASS_COMMAND   @"AUTHINFO PASS"
#define BODY_COMMAND            @"BODY"
#define GROUP_COMMAND           @"GROUP"
#define HELP_COMMAND            @"HELP"
#define LIST_COMMAND            @"LIST"
#define LIST_ACTIVE_COMMAND     @"LIST ACTIVE"
#define POST_COMMAND            @"POST"

#define QUIT_COMMAND            @"QUIT"
#define CAPABILITIES_COMMAND    @"CAPABILITIES"
#define HEAD_COMMAND            @"HEAD"
#define OVER_COMMAND            @"OVER"
#define XOVER_COMMAND           @"XOVER"
#define AUTHINFO_COMMAND        @"AUTHINFO"
#define MODE_READER_COMMAND     @"MODE READER"

NSString *NNConnectionBytesReceivedNotification = @"NNConnectionBytesReceivedNotification";

@interface NNConnection (Private)

- (void)connectAndSendCommandString:(NSString *)commandString
                withParameterString:(NSString *)paramString;
- (void)connectAndSendCommandString:(NSString *)commandString;
- (void)sendCommandString:(NSString *)commandString
      withParameterString:(NSString *)paramString;
- (void)sendCommandString:(NSString *)commandString;
- (void)handleBytes:(UInt8 *)buffer length:(NSUInteger)length;
- (void)reportReadError:(CFErrorRef)error;
- (void)reportWriteError:(CFErrorRef)error;
- (void)reportCompletion;

@end

static void ReadCallBack(CFReadStreamRef stream,
                         CFStreamEventType event,
                         void *info)
{
    UInt8 buf[BUFSIZE];
    
    switch (event)
    {
        case kCFStreamEventOpenCompleted:
        {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:ServerReadOpenCompletedNotification object:(__bridge id)(info)];
            break;
        }
            
        case kCFStreamEventHasBytesAvailable:
        {
            CFIndex bytesRead = CFReadStreamRead(stream, buf, BUFSIZE);
            if (bytesRead > 0)
                [(__bridge NNConnection *)info handleBytes:buf length:bytesRead];
            break;
        }
            
        case kCFStreamEventErrorOccurred:
        {
            CFErrorRef error = CFReadStreamCopyError(stream);
            [(__bridge NNConnection *)info reportReadError:error];
            CFRelease(error);

            CFReadStreamUnscheduleFromRunLoop(stream,
                                              CFRunLoopGetCurrent(),
                                              kCFRunLoopCommonModes);
            CFReadStreamClose(stream);
            CFRelease(stream);
            break;
        }
            
        case kCFStreamEventEndEncountered:
            [(__bridge NNConnection *)info reportCompletion];
            CFReadStreamUnscheduleFromRunLoop(stream,
                                              CFRunLoopGetCurrent(),
                                              kCFRunLoopCommonModes);
            CFReadStreamClose(stream);
            CFRelease(stream);
            break;
    }
}

static void WriteCallBack(CFWriteStreamRef stream,
                          CFStreamEventType event,
                          void *info)
{
    switch (event)
    {
        case kCFStreamEventOpenCompleted:
        {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:ServerWriteOpenCompletedNotification object:(__bridge id)(info)];
            break;
        }
            
        case kCFStreamEventCanAcceptBytes:
        {
            //            CFIndex bytesRead = CFReadStreamRead(stream, buf, BUFSIZE);
            //            if (bytesRead > 0)
            //                [(NNServer *)info handleBytes:buf length:bytesRead];
//            NSLog(@"kCFStreamEventCanAcceptBytes");
            break;
        }
            
        case kCFStreamEventErrorOccurred:
        {
            CFErrorRef error = CFWriteStreamCopyError(stream);
            [(__bridge NNConnection *)info reportWriteError:error];
            CFRelease(error);

            CFWriteStreamUnscheduleFromRunLoop(stream,
                                               CFRunLoopGetCurrent(),
                                               kCFRunLoopCommonModes);
            CFWriteStreamClose(stream);
            CFRelease(stream);
            break;
        }
            
        case kCFStreamEventEndEncountered:
            [(__bridge NNConnection *)info reportCompletion];
            CFWriteStreamUnscheduleFromRunLoop(stream,
                                               CFRunLoopGetCurrent(),
                                               kCFRunLoopCommonModes);
            CFWriteStreamClose(stream);
            CFRelease(stream);
            break;
    }
}

@implementation NNConnection

@synthesize server;
@synthesize responseCode;
@synthesize responseData;

- (id)initWithServer:(NNServer *)aServer
{
    self = [super init];
    if (self)
    {
        server = aServer;
        
        // Notifications we're interested in
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(serverConnected:)
                   name:ServerConnectedNotification
                 object:self];
        [nc addObserver:self
               selector:@selector(serverAuthenticated:)
                   name:ServerAuthenticatedNotification
                 object:self];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"NNConnection Deallocated");
    
    [self disconnect];

    CFHostUnscheduleFromRunLoop(server.host,
                                CFRunLoopGetCurrent(),
                                kCFRunLoopCommonModes);
    CFHostSetClient(server.host, NULL, NULL);
}

- (NSString *)hostName
{
    return server.hostName;
}

- (void)connect
{
    responseCode = 0;

    CFStreamCreatePairWithSocketToCFHost(kCFAllocatorDefault,
                                         server.host,
                                         server.port,
                                         &readStream,
                                         &writeStream);
    
    CFStreamClientContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
    if (CFReadStreamSetClient(readStream,
                              kCFStreamEventOpenCompleted
                              | kCFStreamEventHasBytesAvailable
                              | kCFStreamEventErrorOccurred
                              | kCFStreamEventEndEncountered,
                              ReadCallBack,
                              &context))
    {
        CFReadStreamScheduleWithRunLoop(readStream,
                                        CFRunLoopGetCurrent(),
                                        kCFRunLoopCommonModes);
    }
    
    if (CFWriteStreamSetClient(writeStream,
                               kCFStreamEventOpenCompleted
                               | kCFStreamEventCanAcceptBytes
                               | kCFStreamEventErrorOccurred
                               | kCFStreamEventEndEncountered,
                               WriteCallBack,
                               &context))
    {
        CFWriteStreamScheduleWithRunLoop(writeStream,
                                         CFRunLoopGetCurrent(),
                                         kCFRunLoopCommonModes);
    }
    
    if (!CFReadStreamOpen(readStream))
    {
        CFStreamError myErr = CFReadStreamGetError(readStream);
        
        NSLog(@"err: %d, %d", myErr.domain, myErr.error);
        
        // An error has occurred.
        if (myErr.domain == kCFStreamErrorDomainPOSIX)
        {
            // Interpret myErr.error as a UNIX errno.
        }
        else if (myErr.domain == kCFStreamErrorDomainMacOSStatus)
        {
            // Interpret myErr.error as a MacOS error code.
            //OSStatus macError = (OSStatus)myErr.error;
            // Check other error domains.
        }
    }
    
    if (!CFWriteStreamOpen(writeStream))
    {
        CFStreamError myErr = CFWriteStreamGetError(writeStream);
        
        // An error has occurred.
        if (myErr.domain == kCFStreamErrorDomainPOSIX)
        {
            // Interpret myErr.error as a UNIX errno.
        }
        else if (myErr.domain == kCFStreamErrorDomainMacOSStatus)
        {
            // Interpret myErr.error as a MacOS error code.
            //OSStatus macError = (OSStatus)myErr.error;
            // Check other error domains.
        }
    }
}

- (void)disconnect
{
    // Don't try to disconnect if we're not connected.  Presently, when an
    // error is encountered, then streams are automatically removed from the
    // run loop and closed.  If we try to do it again here, then it crashes.
    if (connected == NO)
        return;

    if (readStream)
    {
        CFReadStreamUnscheduleFromRunLoop(readStream,
                                          CFRunLoopGetCurrent(),
                                          kCFRunLoopCommonModes);
        CFReadStreamClose(readStream);
        CFRelease(readStream);
        readStream = 0;
    }
    
    if (writeStream)
    {
        CFWriteStreamUnscheduleFromRunLoop(writeStream,
                                           CFRunLoopGetCurrent(),
                                           kCFRunLoopCommonModes);
        CFWriteStreamClose(writeStream);
        CFRelease(writeStream);
        writeStream = 0;
    }

    connected = NO;
    issuedModeReaderCommand = NO;
    deferredCommandString = nil;
    executingCommand = NO;

    [server.delegate endNetworkAccessForServer:server];
}

- (void)writeData:(NSData *)data
{
    responseCode = 0;

    // TODO We need to scan through the buffer and escape any lines that
    // contain a single period ('.') as the only line
    CFIndex bytesWritten = CFWriteStreamWrite(writeStream,
                                              data.bytes,
                                              data.length);
    if (bytesWritten < 0)
    {
        //        CFStreamError error = CFWriteStreamGetError(writeStream);
        //        reportError(error);
    }
    else if (bytesWritten != data.length)
    {
        //        // Determine how much has been written and adjust the buffer
        //        bufLen = bufLen - bytesWritten;
        //        memmove(buf, buf + bytesWritten, bufLen);
        //        
        //        // Figure out what went wrong with the write stream
        //        CFStreamError error = CFWriteStreamGetError(myWriteStream);
        //        reportError(error);
        
    }

    // Terminate the stream
    bytesWritten = CFWriteStreamWrite(writeStream, (const UInt8 *)"\r\n.\r\n", 5);
}

#pragma mark -
#pragma mark NNTP Commands

- (void)articleWithMessageId:(NSString *)messageId
{
    [self connectAndSendCommandString:ARTICLE_COMMAND
                  withParameterString:messageId];
}

- (void)bodyWithMessageId:(NSString *)messageId
{
    [self connectAndSendCommandString:BODY_COMMAND
                  withParameterString:messageId];
}

- (void)groupWithName:(NSString *)groupName
{
    [self connectAndSendCommandString:GROUP_COMMAND
                  withParameterString:groupName];
}

- (void)help
{
    [self connectAndSendCommandString:HELP_COMMAND];
}

- (void)list
{
    [self connectAndSendCommandString:LIST_COMMAND];
}

- (void)listActiveWithWildmat:(NSString *)wildmat
{
    [self connectAndSendCommandString:LIST_ACTIVE_COMMAND
                  withParameterString:wildmat];
}

- (void)overWithRange:(NSRange)articleRange
{
    [self connectAndSendCommandString:XOVER_COMMAND
                  withParameterString:[NSString stringWithFormat:@"%d-%d",
                                       articleRange.location,
                                       articleRange.location + articleRange.length - 1]];
}

- (void)post
{
    [self connectAndSendCommandString:POST_COMMAND];
}

#pragma mark -
#pragma mark Notifications

- (void)serverConnected:(NSNotification *)notification
{
    // Do we have authentication info?  If so, then authenticate now.
    NSString *userName = [server.delegate userNameForServer:server];
    if (userName && [userName isEqualToString:@""] == NO)
    {
        [self sendCommandString:AUTHINFO_USER_COMMAND
            withParameterString:userName];
        return;
    }
    
    // Check if we have a deferred command that is waiting for this
    // connection to be established
    if (deferredCommandString)
        [self sendCommandString:deferredCommandString];
}

- (void)serverAuthenticated:(NSNotification *)notification
{
    // Check if we have a deferred command that is waiting for this
    // connection to be authenticated
    if (deferredCommandString)
        [self sendCommandString:deferredCommandString];
}

#pragma mark -
#pragma mark Private Methods

- (void)connectAndSendCommandString:(NSString *)commandString
                withParameterString:(NSString *)paramString
{
    commandString = [commandString stringByAppendingFormat:@" %@", paramString];
    [self connectAndSendCommandString:commandString];
}

- (void)connectAndSendCommandString:(NSString *)commandString
{
    // If the connection is yet to be connected, start doing so, and defer
    // the command until the ServerConnectedNotification is generated
    if (!connected)
    {
        deferredCommandString = [commandString copy];
        [self connect];
    }
    else
        [self sendCommandString:commandString];
}

- (void)sendCommandString:(NSString *)commandString
      withParameterString:(NSString *)paramString
{
    commandString = [commandString stringByAppendingFormat:@" %@", paramString];
    [self sendCommandString:commandString];
}

- (void)sendCommandString:(NSString *)commandString
{
    responseCode = 0;

    if (executingCommand || !connected)
        return;
    
    NSLog(@"Command: %@", commandString);
    
    UInt8 buf[512];
    NSUInteger count;
    
    // Convert to a UTF-8 string
    NSRange range = NSMakeRange(0, [commandString length]);
    [commandString getBytes:buf
                  maxLength:510
                 usedLength:&count
                   encoding:NSUTF8StringEncoding
                    options:NSStringEncodingConversionAllowLossy
                      range:range
             remainingRange:NULL];
    buf[count] = 13;
    buf[count + 1] = 10;
    count += 2;

    [server.delegate beginNetworkAccessForServer:server];
    
    CFIndex bytesWritten = CFWriteStreamWrite(writeStream, buf, count);
    if (bytesWritten < 0)
    {
        //        CFStreamError error = CFWriteStreamGetError(writeStream);
        //        reportError(error);
    }
    else if (bytesWritten != count)
    {
        //        // Determine how much has been written and adjust the buffer
        //        bufLen = bufLen - bytesWritten;
        //        memmove(buf, buf + bytesWritten, bufLen);
        //        
        //        // Figure out what went wrong with the write stream
        //        CFStreamError error = CFWriteStreamGetError(myWriteStream);
        //        reportError(error);
        
    }
    
    executingCommand = YES;
}

- (BOOL)isMultilineResponse
{
    switch (responseCode)
    {
        case 100:   // Help text follows
        case 215:   // List information follows
        case 220:   // Article follows
        case 221:   // Headers follows
        case 222:   // Body follows
        case 224:   // Overview information follows
            return YES;
    }
    return NO;
}

- (BOOL)isResponseTerminated
{
    if (responseCode == 0)
    {
//        NSLog(@"NOT Terminated (responseCode == 0)");
        return NO;
    }
    
    if ([self isMultilineResponse])
    {
        const unsigned char *bytes = responseByteBuffer;
        if (responseLength >= 5
            && bytes[responseLength - 5] == 13
            && bytes[responseLength - 4] == 10
            && bytes[responseLength - 3] == '.'
            && bytes[responseLength - 2] == 13
            && bytes[responseLength - 1] == 10)
        {
//            NSLog(@"TERMINATED");
            return YES;
        }
        else if (lastHandledBytesEndedWithCRLF
                 && responseLength >= 3
                 && bytes[responseLength - 3] == '.'
                 && bytes[responseLength - 2] == 13
                 && bytes[responseLength - 1] == 10)
        {
//            NSLog(@"TERMINATED (previous CRLF)");
            return YES;
        }
    }
    else
    {
        const unsigned char *bytes = responseByteBuffer;
        NSUInteger i = responseLength - 2;
        if (bytes[i] == 13 && bytes[i + 1] == 10)
        {
//            NSLog(@"TERMINATED");
            return YES;
        }
    }

//    NSLog(@"NOT Terminated");
    
    return NO;
}

- (void)reportAuthenticationFailed
{
    // We are unable to work with any deferred commands
    deferredCommandString = nil;
    
    // Authentication failed
    NSString *message = [[NSString alloc] initWithBytes:responseByteBuffer
                                                 length:responseLength - 2
                                               encoding:NSASCIIStringEncoding];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              message, @"Message",
                              nil];

    NSNotification *notification =
    [NSNotification notificationWithName:ServerAuthenticationFailedNotification
                                  object:self
                                userInfo:userInfo];
    NSNotificationQueue *nq = [NSNotificationQueue defaultQueue];
    [nq enqueueNotification:notification
               postingStyle:NSPostWhenIdle];
}

- (void)responseCompleted
{
    // Data is terminated, so no further data is expected
    executingCommand = NO;
    [server.delegate endNetworkAccessForServer:server];
    
    NSLog(@"Response: %d", responseCode);

    if (responseCode == 200 && issuedModeReaderCommand == NO)
    {
        // Initial connection response -- we are now connected.
        // Set to MODE READER.
        connected = YES;
        issuedModeReaderCommand = YES;
        [self sendCommandString:MODE_READER_COMMAND];
    }
    else if (responseCode == 200 || responseCode == 201)
    {
        // We are now connected and MODE READER
        NSNotification *notification =
        [NSNotification notificationWithName:ServerConnectedNotification
                                      object:self];
        NSNotificationQueue *nq = [NSNotificationQueue defaultQueue];
        [nq enqueueNotification:notification
                   postingStyle:NSPostWhenIdle];
    }
    else if (responseCode == 480)
    {
        // Authentication required -- send user name
        NSString *userName = [server.delegate userNameForServer:server];
        if (userName == nil || [userName isEqualToString:@""])
            [self reportAuthenticationFailed];
        else
            [self sendCommandString:AUTHINFO_USER_COMMAND
                withParameterString:userName];
    }
    else if (responseCode == 381)
    {
        // More authentication required -- send password
        NSString *password = [server.delegate passwordForServer:server];
        if (password == nil || [password isEqualToString:@""])
            [self reportAuthenticationFailed];
        else
            [self sendCommandString:AUTHINFO_PASS_COMMAND
                withParameterString:password];
    }
    else if (responseCode == 281)
    {
        // Authentication completed
        NSNotification *notification =
        [NSNotification notificationWithName:ServerAuthenticatedNotification
                                      object:self];
        NSNotificationQueue *nq = [NSNotificationQueue defaultQueue];
        [nq enqueueNotification:notification
                   postingStyle:NSPostWhenIdle];
    }
    else if (responseCode == 481)
    {
        // Authentication failed
        [self reportAuthenticationFailed];
    }
    else if (responseCode == 501)
    {
        // Syntax error in the command
    }
    else if (responseCode == 503)
    {
        // Disconnection notification -- we are no longer connected
        // [NNConnection reportCompletion] will be called
    }
    else
    {
        // We are finished with any deferred commands
        deferredCommandString = nil;

        // A command has completed
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:ServerCommandRespondedNotification
                          object:self];
    }
}

- (void)handleBytes:(UInt8 *)buffer length:(NSUInteger)length
{
    if (responseCode == 0)
    {
        if (isdigit(buffer[0]) && isdigit(buffer[1]) && isdigit(buffer[2]))
            responseCode = 100 * (buffer[0] - '0') + 10 * (buffer[1] - '0') + (buffer[2] - '0');
    }

//    NSString *str = [NSString stringWithCString:buffer length:length];
//    NSLog(@"handleBytes: %@", str);
    
    // Notify interested parties of the received data
    responseData = [[NSData alloc] initWithBytesNoCopy:buffer
                                                length:length
                                          freeWhenDone:NO];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:NNConnectionBytesReceivedNotification object:self];

    // TODO This is still a bit hacky -- clean it up
    responseByteBuffer = buffer;
    responseLength = length;
    
    if ([self isResponseTerminated])
    {
        [self responseCompleted];
    }
    
    // To help us work out when the response is terminated, we'll note if the
    // end of this buffer contains a CRLF pair
    if (buffer[length - 2] == 13 && buffer[length - 1] == 10)
        lastHandledBytesEndedWithCRLF = YES;
    else
        lastHandledBytesEndedWithCRLF = NO;

    responseData = nil;
}

- (void)reportReadError:(CFErrorRef)error
{
    connected = NO;
    issuedModeReaderCommand = NO;
    
    NSString *errorDesc = (NSString *)CFBridgingRelease(CFErrorCopyDescription(error));
    NSString *errorDomain = (NSString *)CFErrorGetDomain(error);
    CFIndex errorCode = CFErrorGetCode(error);

    if ([errorDomain isEqualToString:(NSString *)kCFErrorDomainCFNetwork])
    {
        if (errorCode == kCFHostErrorUnknown)
        {
            NSNumber *addrInfoFailure = (NSNumber *)CFBridgingRelease(CFReadStreamCopyProperty(readStream,
                                                                             kCFGetAddrInfoFailureKey));
        }
    }
    
    NSLog(@"reportReadError: (%@ %d)(%@)", errorDomain, errorCode, errorDesc);
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:ServerReadErrorNotification object:self];
}

- (void)reportWriteError:(CFErrorRef)error
{
    connected = NO;
    issuedModeReaderCommand = NO;

    NSString *errorDesc = (NSString *)CFBridgingRelease(CFErrorCopyDescription(error));
    NSString *errorDomain = (NSString *)CFErrorGetDomain(error);
    CFIndex errorCode = CFErrorGetCode(error);
    
    NSLog(@"reportWriteError: (%@ %d)(%@)", errorDomain, errorCode, errorDesc);

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:ServerWriteErrorNotification object:self];
}

- (void)reportCompletion
{
    connected = NO;
    issuedModeReaderCommand = NO;
    NSLog(@"reportCompletion");

    [server.delegate endNetworkAccessForServer:server];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:ServerDisconnectedNotification object:self];
}

@end
