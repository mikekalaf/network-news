//
//  NewsConnection.m
//  NetworkNews
//
//  Created by David Schweinsberg on 8/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "NewsConnection.h"
#import "NewsResponse.h"

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

@interface NewsConnection () <NSStreamDelegate>
{
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
    BOOL _secure;
}

@end

@implementation NewsConnection

- (id)initWithHost:(NSString *)host port:(NSUInteger)port isSecure:(BOOL)secure
{
    self = [super init];
    if (self)
    {
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(NULL,
                                           (__bridge CFStringRef)host,
                                           port,
                                           &readStream,
                                           &writeStream);

        _inputStream = (__bridge_transfer NSInputStream *)readStream;
        _outputStream = (__bridge_transfer NSOutputStream *)writeStream;
        [_inputStream setDelegate:self];
        [_outputStream setDelegate:self];
        [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

        // Sort out any required SSL
        _secure = secure;
        if (_secure)
        {
            [_inputStream setProperty:NSStreamSocketSecurityLevelSSLv2
                               forKey:NSStreamSocketSecurityLevelKey];
            [_outputStream setProperty:NSStreamSocketSecurityLevelSSLv2
                                forKey:NSStreamSocketSecurityLevelKey];
        }
        
        [_inputStream open];
        [_outputStream open];

        // We're expecting a 200 response when we connect successfully
        NewsResponse *response = [self readResponse];
        if ([response statusCode] == 200)
        {
            _welcome = [[NSString alloc] initWithData:[response data] encoding:NSUTF8StringEncoding];
            NSLog(@"Connected: %@", _welcome);
        }
        else
        {
            NSLog(@"FAILED to connect");
        }
    }
    return self;
}

- (void)dealloc
{
    [_inputStream close];
    _inputStream = nil;

    [_outputStream close];
    _outputStream = nil;
}

- (void)handleInputStreamEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent)
    {
        case NSStreamEventOpenCompleted:
        {
            break;
        }

        case NSStreamEventHasBytesAvailable:
        {
            break;
        }

        case NSStreamEventErrorOccurred:
        {
            break;
        }

        case NSStreamEventEndEncountered:
        {
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
            break;
        }

        case NSStreamEventHasSpaceAvailable:
            break;

        case NSStreamEventHasBytesAvailable:
            break;

        case NSStreamEventErrorOccurred:
        {
            break;
        }

        case NSStreamEventEndEncountered:
        {
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

#pragma mark - Private Methods

- (void)sendCommandString:(NSString *)commandString
      withParameterString:(NSString *)paramString
{
    commandString = [commandString stringByAppendingFormat:@" %@", paramString];
    return [self sendCommandString:commandString];
}

- (void)sendCommandString:(NSString *)commandString
{
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
}

- (NewsResponse *)readResponse
{
    return [self readResponseWithCode:0];
}

- (NewsResponse *)readResponseWithCode:(NSInteger)terminatingStatusCode
{
    NSMutableData *responseData = [[NSMutableData alloc] init];
    NSInteger statusCode = 0;
    const int BUFSIZE = 65535;
    uint8_t buffer[BUFSIZE];
    while (YES)
    {
        unsigned int bytesRead = [_inputStream read:buffer maxLength:BUFSIZE];
        if (bytesRead > 0)
        {
            NSLog(@"%d bytes read", bytesRead);

            if (statusCode == 0 && isdigit(buffer[0]) && isdigit(buffer[1]) && isdigit(buffer[2]))
                statusCode = 100 * (buffer[0] - '0') + 10 * (buffer[1] - '0') + (buffer[2] - '0');

            NSString *str = [[NSString alloc] initWithBytes:buffer length:bytesRead encoding:NSUTF8StringEncoding];
            NSLog(@"handleBytes: %@", str);

            [responseData appendBytes:buffer length:bytesRead];

            if (statusCode == terminatingStatusCode)
            {
                if ([self isMultilineTerminatedData:responseData])
                    break;
            }
            else if ([self isLineTerminatedData:responseData])
                break;
        }
        else
        {
            break;
        }
    }

    return [[NewsResponse alloc] initWithData:responseData statusCode:statusCode];
}

- (BOOL)isMultilineTerminatedData:(NSData *)data
{
    const unsigned char *bytes = [data bytes];
    NSUInteger len = [data length];
    if (len >= 5
        && bytes[len - 5] == 13
        && bytes[len - 4] == 10
        && bytes[len - 3] == '.'
        && bytes[len - 2] == 13
        && bytes[len - 1] == 10)
    {
        return YES;
    }

    return NO;
}

- (BOOL)isLineTerminatedData:(NSData *)data
{
    const unsigned char *bytes = [data bytes];
    NSUInteger len = [data length];
    if (len > 2 && bytes[len - 2] == 13 && bytes[len - 1] == 10)
    {
        return YES;
    }

    return NO;
}

#pragma mark - Public Methods

- (void)loginWithUser:(NSString *)user password:(NSString *)password
{
    [self sendCommandString:AUTHINFO_USER_COMMAND withParameterString:user];
    NewsResponse *response = [self readResponse];

    if ([response statusCode] == 381)
    {
        [self sendCommandString:AUTHINFO_PASS_COMMAND withParameterString:password];
        response = [self readResponse];

        if ([response statusCode] == 281)
        {
            // Success
            NSLog(@"Successful log in");
        }
        else if ([response statusCode] == 481)
        {
            // Failure
            NSLog(@"Failed to log in");
        }
    }
}

- (NewsResponse *)listActiveWithWildmat:(NSString *)wildmat
{
    [self sendCommandString:LIST_ACTIVE_COMMAND withParameterString:wildmat];
    NewsResponse *response = [self readResponseWithCode:215];

    return response;
}

- (NewsResponse *)articleWithMessageID:(NSString *)messageID
{
    [self sendCommandString:ARTICLE_COMMAND withParameterString:messageID];
    NewsResponse *response = [self readResponseWithCode:220];
    return response;
}

- (NewsResponse *)bodyWithMessageID:(NSString *)messageID
{
    [self sendCommandString:BODY_COMMAND withParameterString:messageID];
    NewsResponse *response = [self readResponseWithCode:222];
    return response;
}

- (NewsResponse *)groupWithName:(NSString *)groupName
{
    [self sendCommandString:GROUP_COMMAND withParameterString:groupName];
    return [self readResponse];
}

- (NewsResponse *)overWithRange:(ArticleRange)articleRange;
{
    [self sendCommandString:XOVER_COMMAND
        withParameterString:[NSString stringWithFormat:@"%lld-%lld",
                             articleRange.location,
                             articleRange.location + articleRange.length - 1]];
    return [self readResponseWithCode:224];
}

- (NewsResponse *)quit
{
    [self sendCommandString:QUIT_COMMAND];
    NewsResponse *response = [self readResponse];

    [_inputStream close];
    _inputStream = nil;

    [_outputStream close];
    _outputStream = nil;

    return response;
}

- (NewsResponse *)capabilities
{
    [self sendCommandString:CAPABILITIES_COMMAND];
    NewsResponse *response = [self readResponseWithCode:101];

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    if ([response statusCode] == 101)
    {
        NSArray *capabilities = [[response string] componentsSeparatedByString:@"\r\n"];
        for (NSUInteger i = 1; i < [capabilities count] - 2; ++i)
        {
            NSString *capability = capabilities[i];
            NSArray *components = [capability componentsSeparatedByString:@" "];
            if ([components count] > 1)
                dict[components[0]] = [components subarrayWithRange:NSMakeRange(1, [components count] - 1)];
            else
                dict[components[0]] = [NSNull null];
        }
        [response setDictionary:dict];
    }

    return response;
}

@end
