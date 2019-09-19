//
//  NNArticleFormatter.m
//  Network News
//
//  Created by David Schweinsberg on 11/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NNArticleFormatter.h"
#import "NNHeaderEntry.h"
#import "NSData+NewsAdditions.h"
#import "NewsKit.h"

@implementation NNArticleFormatter

+ (NSArray *)headerArrayWithDate:(NSDate *)date
                            from:(NSString *)from
                         replyTo:(NSString *)replyTo
                    organization:(NSString *)organization
                       messageId:(NSString *)messageId
                      references:(NSString *)references
                      newsgroups:(NSString *)newsgroups
                         subject:(NSString *)subject {
  NSBundle *bundle = [NSBundle mainBundle];
  NSDictionary *infoDict = bundle.infoDictionary;

#if TARGET_OS_IPHONE

  UIDevice *device = [UIDevice currentDevice];

  // Build the user-agent string
  NSString *userAgent = [NSString
      stringWithFormat:@"%@/%@b%@ (%@ %@; %@)", APP_NAME_TOKEN,
                       infoDict[@"CFBundleShortVersionString"],
                       infoDict[@"CFBundleVersion"], device.systemName,
                       device.systemVersion, device.model];
#elif TARGET_OS_MAC

  // Get the system version
  SInt32 major;
  SInt32 minor;
  SInt32 bugFix;
  Gestalt(gestaltSystemVersionMajor, &major);
  Gestalt(gestaltSystemVersionMinor, &minor);
  Gestalt(gestaltSystemVersionBugFix, &bugFix);

  // Build the user-agent string
  NSString *userAgent = [NSString
      stringWithFormat:@"%@/%@b%@ (%@ %d.%d.%d)", APP_NAME_TOKEN,
                       [infoDict objectForKey:@"CFBundleShortVersionString"],
                       [infoDict objectForKey:@"CFBundleVersion"], OS_NAME,
                       major, minor, bugFix];
#endif

  NSMutableArray *headers = [NSMutableArray arrayWithCapacity:5];

  // Format the date according to RFC 5322
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z";
  [headers addObject:[[NNHeaderEntry alloc]
                         initWithName:@"Date"
                                value:[dateFormatter stringFromDate:date]]];

  [headers addObject:[[NNHeaderEntry alloc] initWithName:@"From" value:from]];
  [headers addObject:[[NNHeaderEntry alloc] initWithName:@"Newsgroups"
                                                   value:newsgroups]];
  [headers addObject:[[NNHeaderEntry alloc] initWithName:@"Subject"
                                                   value:subject]];
  if (references && [references isEqualToString:@""] == NO)
    [headers addObject:[[NNHeaderEntry alloc] initWithName:@"References"
                                                     value:references]];
  if (replyTo && [replyTo isEqualToString:@""] == NO)
    [headers addObject:[[NNHeaderEntry alloc] initWithName:@"Reply-To"
                                                     value:replyTo]];
  if (organization && [organization isEqualToString:@""] == NO)
    [headers addObject:[[NNHeaderEntry alloc] initWithName:@"Organization"
                                                     value:organization]];
  [headers addObject:[[NNHeaderEntry alloc] initWithName:@"User-Agent"
                                                   value:userAgent]];
  return headers;
}

+ (NSData *)articleDataWithHeaders:(NSArray *)headers
                              text:(NSString *)text
                      formatFlowed:(BOOL)formatFlowed {
  NSMutableData *data = [NSMutableData data];
  const char *bytes;

  // Determine the encoding to use and add the MIME headers
  NSString *contentType;
  NSString *contentTransferEncoding;
  NSStringEncoding stringEncoding;
  if ([text canBeConvertedToEncoding:NSASCIIStringEncoding]) {
    contentType = @"text/plain; charset=us-ascii";
    contentTransferEncoding = @"7bit";
    stringEncoding = NSASCIIStringEncoding;
  } else if ([text canBeConvertedToEncoding:NSISOLatin1StringEncoding]) {
    contentType = @"text/plain; charset=iso-8859-1";
    contentTransferEncoding = @"8bit";
    stringEncoding = NSISOLatin1StringEncoding;
  } else {
    contentType = @"text/plain; charset=utf-8";
    contentTransferEncoding = @"8bit";
    stringEncoding = NSUTF8StringEncoding;
  }

  if (formatFlowed)
    contentType = [contentType stringByAppendingString:@"; format=flowed"];

  NSMutableArray *mimeHeaders = [NSMutableArray arrayWithCapacity:3];
  [mimeHeaders addObject:[[NNHeaderEntry alloc] initWithName:@"MIME-Version"
                                                       value:@"1.0"]];
  [mimeHeaders addObject:[[NNHeaderEntry alloc] initWithName:@"Content-Type"
                                                       value:contentType]];
  [mimeHeaders
      addObject:[[NNHeaderEntry alloc] initWithName:@"Content-Transfer-Encoding"
                                              value:contentTransferEncoding]];
  NSArray *completeHeaders =
      [headers arrayByAddingObjectsFromArray:mimeHeaders];

  // Build the header
  for (NNHeaderEntry *header in completeHeaders) {
    bytes = header.name.UTF8String;
    [data appendBytes:bytes length:strlen(bytes)];
    [data appendBytes:": " length:2];

    bytes = header.value.UTF8String;
    [data appendBytes:bytes length:strlen(bytes)];
    [data appendBytes:"\r\n" length:2];
  }
  [data appendBytes:"\r\n" length:2];

  // Append the body text, ensuring each line is terminated with a CRLF
  NSData *encodedTextData = [text dataUsingEncoding:stringEncoding];
  [data appendData:[encodedTextData dataWithCRLFs]];

  return data;
}

@end
