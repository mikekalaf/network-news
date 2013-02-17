//
//  ContentType.h
//  Network News
//
//  Created by David Schweinsberg on 6/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContentType : NSObject
{
    NSString *mediaType;
    NSString *charset;
    NSString *format;
}

@property(nonatomic, copy) NSString *mediaType;
@property(nonatomic, copy) NSString *charset;
@property(nonatomic, copy) NSString *format;
@property(nonatomic, readonly, getter=isFormatFlowed) BOOL formatFlowed;

- (id)initWithString:(NSString *)string;

@end
