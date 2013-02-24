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

@interface NNConnection () <NSStreamDelegate>
{
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;

    NSString *_deferredCommandString;
    BOOL _connected;
    BOOL _executingCommand;

    const UInt8 *_responseByteBuffer;
    NSUInteger _responseLength;
    BOOL _lastHandledBytesEndedWithCRLF;
    BOOL _issuedModeReaderCommand;
}

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


@implementation NNConnection

- (id)initWithServer:(NNServer *)aServer
{
    self = [super init];
    if (self)
    {
        _server = aServer;
        
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

    CFHostUnscheduleFromRunLoop(_server.host,
                                CFRunLoopGetCurrent(),
                                kCFRunLoopCommonModes);
    CFHostSetClient(_server.host, NULL, NULL);
}

- (NSString *)hostName
{
    return _server.hostName;
}

- (void)connect
{
    _responseCode = 0;

    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToCFHost(kCFAllocatorDefault,
                                         [_server host],
                                         [_server port],
                                         &readStream,
                                         &writeStream);
    
    _inputStream = (__bridge_transfer NSInputStream *)readStream;
    _outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    [_inputStream setDelegate:self];
    [_outputStream setDelegate:self];
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_inputStream open];
    [_outputStream open];
}

- (void)disconnect
{
    // Don't try to disconnect if we're not connected.  Presently, when an
    // error is encountered, then streams are automatically removed from the
    // run loop and closed.  If we try to do it again here, then it crashes.
    if (_connected == NO)
        return;

    if (_inputStream)
    {
        [_inputStream close];
        _inputStream = nil;
    }

    if (_outputStream)
    {
        [_outputStream close];
        _outputStream = nil;
    }

    _connected = NO;
    _issuedModeReaderCommand = NO;
    _deferredCommandString = nil;
    _executingCommand = NO;

    [_server.delegate endNetworkAccessForServer:_server];
}

- (void)writeData:(NSData *)data
{
    _responseCode = 0;

    // TODO: Don't do the actual writing here - instead, see how we do it via
    // the event handling delegate

    // TODO We need to scan through the buffer and escape any lines that
    // contain a single period ('.') as the only line
    NSInteger bytesWritten = [_outputStream write:[data bytes] maxLength:[data length]];

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
    bytesWritten = [_outputStream write:(const UInt8 *)"\r\n.\r\n" maxLength:5];
}

- (void)handleInputStreamEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent)
    {
        case NSStreamEventOpenCompleted:
        {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:ServerReadOpenCompletedNotification object:self];
            break;
        }

        case NSStreamEventHasBytesAvailable:
        {
            // TODO: shift this buffer to the heap
            UInt8 buf[BUFSIZE];
            unsigned int bytesRead = [_inputStream read:buf maxLength:BUFSIZE];
            if (bytesRead > 0)
                [self handleBytes:buf length:bytesRead];
            break;
        }

        case NSStreamEventErrorOccurred:
        {
            //            CFErrorRef error = CFReadStreamCopyError(stream);
            //            [self reportReadError:error];
            [self reportReadError:nil];
            [_inputStream close];
            [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                    forMode:NSDefaultRunLoopMode];
            _inputStream = nil;
            break;
        }

        case NSStreamEventEndEncountered:
        {
            // TODO: This is potentially called twice - once each for read and write
            [self reportCompletion];

            [_inputStream close];
            [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                    forMode:NSDefaultRunLoopMode];
            _inputStream = nil;
            break;
        }

        case NSStreamEventNone:
            break;
            
        case NSStreamEventHasSpaceAvailable:
            break;
    }
}

- (void)handleOutputStreamEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent)
    {
        case NSStreamEventOpenCompleted:
        {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:ServerWriteOpenCompletedNotification object:self];
            break;
        }

        case NSStreamEventHasSpaceAvailable:
            break;

        case NSStreamEventHasBytesAvailable:
            break;

        case NSStreamEventErrorOccurred:
        {
            //            CFErrorRef error = CFReadStreamCopyError(stream);
            //            [self reportReadError:error];
            [self reportWriteError:nil];
            [_outputStream close];
            [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                     forMode:NSDefaultRunLoopMode];
            _outputStream = nil;
            break;
        }

        case NSStreamEventEndEncountered:
        {
            // TODO: This is potentially called twice - once each for read and write
            [self reportCompletion];

            [_outputStream close];
            [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                     forMode:NSDefaultRunLoopMode];
            _outputStream = nil;
            break;
        }

        case NSStreamEventNone:
            break;
    }
}

#pragma mark - NSStreamDelegate Methods

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)streamEvent
{
    if (stream == _inputStream)
        [self handleInputStreamEvent:streamEvent];
    else if (stream == _outputStream)
        [self handleOutputStreamEvent:streamEvent];
}

#pragma mark - NNTP Commands

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
    NSString *userName = [_server.delegate userNameForServer:_server];
    if (userName && [userName isEqualToString:@""] == NO)
    {
        [self sendCommandString:AUTHINFO_USER_COMMAND
            withParameterString:userName];
        return;
    }
    
    // Check if we have a deferred command that is waiting for this
    // connection to be established
    if (_deferredCommandString)
        [self sendCommandString:_deferredCommandString];
}

- (void)serverAuthenticated:(NSNotification *)notification
{
    // Check if we have a deferred command that is waiting for this
    // connection to be authenticated
    if (_deferredCommandString)
        [self sendCommandString:_deferredCommandString];
}

#pragma mark - Private Methods

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
    if (!_connected)
    {
        _deferredCommandString = [commandString copy];
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
    _responseCode = 0;

    if (_executingCommand || !_connected)
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

    [_server.delegate beginNetworkAccessForServer:_server];
    
    NSInteger bytesWritten = [_outputStream write:buf maxLength:count];
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
    
    _executingCommand = YES;
}

- (BOOL)isMultilineResponse
{
    switch (_responseCode)
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
    if (_responseCode == 0)
    {
//        NSLog(@"NOT Terminated (responseCode == 0)");
        return NO;
    }
    
    if ([self isMultilineResponse])
    {
        const unsigned char *bytes = _responseByteBuffer;
        if (_responseLength >= 5
            && bytes[_responseLength - 5] == 13
            && bytes[_responseLength - 4] == 10
            && bytes[_responseLength - 3] == '.'
            && bytes[_responseLength - 2] == 13
            && bytes[_responseLength - 1] == 10)
        {
//            NSLog(@"TERMINATED");
            return YES;
        }
        else if (_lastHandledBytesEndedWithCRLF
                 && _responseLength >= 3
                 && bytes[_responseLength - 3] == '.'
                 && bytes[_responseLength - 2] == 13
                 && bytes[_responseLength - 1] == 10)
        {
//            NSLog(@"TERMINATED (previous CRLF)");
            return YES;
        }
    }
    else
    {
        const unsigned char *bytes = _responseByteBuffer;
        NSUInteger i = _responseLength - 2;
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
    _deferredCommandString = nil;
    
    // Authentication failed
    NSString *message = [[NSString alloc] initWithBytes:_responseByteBuffer
                                                 length:_responseLength - 2
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
    _executingCommand = NO;
    [_server.delegate endNetworkAccessForServer:_server];
    
    NSLog(@"Response: %d", _responseCode);

    if (_responseCode == 200 && _issuedModeReaderCommand == NO)
    {
        // Initial connection response -- we are now connected.
        // Set to MODE READER.
        _connected = YES;
        _issuedModeReaderCommand = YES;
        [self sendCommandString:MODE_READER_COMMAND];
    }
    else if (_responseCode == 200 || _responseCode == 201)
    {
        // We are now connected and MODE READER
        NSNotification *notification =
        [NSNotification notificationWithName:ServerConnectedNotification
                                      object:self];
        NSNotificationQueue *nq = [NSNotificationQueue defaultQueue];
        [nq enqueueNotification:notification
                   postingStyle:NSPostWhenIdle];
    }
    else if (_responseCode == 480)
    {
        // Authentication required -- send user name
        NSString *userName = [_server.delegate userNameForServer:_server];
        if (userName == nil || [userName isEqualToString:@""])
            [self reportAuthenticationFailed];
        else
            [self sendCommandString:AUTHINFO_USER_COMMAND
                withParameterString:userName];
    }
    else if (_responseCode == 381)
    {
        // More authentication required -- send password
        NSString *password = [_server.delegate passwordForServer:_server];
        if (password == nil || [password isEqualToString:@""])
            [self reportAuthenticationFailed];
        else
            [self sendCommandString:AUTHINFO_PASS_COMMAND
                withParameterString:password];
    }
    else if (_responseCode == 281)
    {
        // Authentication completed
        NSNotification *notification =
        [NSNotification notificationWithName:ServerAuthenticatedNotification
                                      object:self];
        NSNotificationQueue *nq = [NSNotificationQueue defaultQueue];
        [nq enqueueNotification:notification
                   postingStyle:NSPostWhenIdle];
    }
    else if (_responseCode == 481)
    {
        // Authentication failed
        [self reportAuthenticationFailed];
    }
    else if (_responseCode == 501)
    {
        // Syntax error in the command
    }
    else if (_responseCode == 503)
    {
        // Disconnection notification -- we are no longer connected
        // [NNConnection reportCompletion] will be called
    }
    else
    {
        // We are finished with any deferred commands
        _deferredCommandString = nil;

        // A command has completed
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:ServerCommandRespondedNotification
                          object:self];
    }
}

- (void)handleBytes:(UInt8 *)buffer length:(NSUInteger)length
{
    if (_responseCode == 0)
    {
        if (isdigit(buffer[0]) && isdigit(buffer[1]) && isdigit(buffer[2]))
            _responseCode = 100 * (buffer[0] - '0') + 10 * (buffer[1] - '0') + (buffer[2] - '0');
    }

//    NSString *str = [NSString stringWithCString:buffer length:length];
//    NSLog(@"handleBytes: %@", str);
    
    // Notify interested parties of the received data
    _responseData = [[NSData alloc] initWithBytesNoCopy:buffer
                                                 length:length
                                          freeWhenDone:NO];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:NNConnectionBytesReceivedNotification object:self];

    // TODO This is still a bit hacky -- clean it up
    _responseByteBuffer = buffer;
    _responseLength = length;
    
    if ([self isResponseTerminated])
    {
        [self responseCompleted];
    }
    
    // To help us work out when the response is terminated, we'll note if the
    // end of this buffer contains a CRLF pair
    if (buffer[length - 2] == 13 && buffer[length - 1] == 10)
        _lastHandledBytesEndedWithCRLF = YES;
    else
        _lastHandledBytesEndedWithCRLF = NO;

    _responseData = nil;
}

- (void)reportReadError:(CFErrorRef)error
{
    _connected = NO;
    _issuedModeReaderCommand = NO;
    
    NSString *errorDesc = (NSString *)CFBridgingRelease(CFErrorCopyDescription(error));
    NSString *errorDomain = (NSString *)CFErrorGetDomain(error);
    CFIndex errorCode = CFErrorGetCode(error);

    if ([errorDomain isEqualToString:(NSString *)kCFErrorDomainCFNetwork])
    {
        if (errorCode == kCFHostErrorUnknown)
        {
//            NSNumber *addrInfoFailure = (NSNumber *)CFBridgingRelease(CFReadStreamCopyProperty(readStream,
//                                                                             kCFGetAddrInfoFailureKey));
        }
    }
    
    NSLog(@"reportReadError: (%@ %ld)(%@)", errorDomain, errorCode, errorDesc);
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:ServerReadErrorNotification object:self];
}

- (void)reportWriteError:(CFErrorRef)error
{
    _connected = NO;
    _issuedModeReaderCommand = NO;

    NSString *errorDesc = (NSString *)CFBridgingRelease(CFErrorCopyDescription(error));
    NSString *errorDomain = (NSString *)CFErrorGetDomain(error);
    CFIndex errorCode = CFErrorGetCode(error);
    
    NSLog(@"reportWriteError: (%@ %ld)(%@)", errorDomain, errorCode, errorDesc);

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:ServerWriteErrorNotification object:self];
}

- (void)reportCompletion
{
    _connected = NO;
    _issuedModeReaderCommand = NO;
    NSLog(@"reportCompletion");

    [_server.delegate endNetworkAccessForServer:_server];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:ServerDisconnectedNotification object:self];
}

@end
