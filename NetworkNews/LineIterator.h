//
//  LineIterator.h
//  Network News
//
//  Created by David Schweinsberg on 15/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LineIterator : NSObject
{
    NSData *data;
    NSUInteger position;
    BOOL partial;
    NSUInteger lineNumber;
}

@property(readonly) BOOL partial;

@property(readonly) BOOL isAtEnd;

@property(readonly) NSUInteger lineNumber;

- (instancetype)initWithData:(NSData *)aData NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

/*!
 Returns a single line as terminated by a CRLF in the data.  The string (if
 complete) includes the terminating CRLF.  If there is no CRLF in the data, and
 thus in the string, then the line is flagged as "partial".
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *nextLine;

@end
