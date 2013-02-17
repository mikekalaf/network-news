//
//  ContentType.m
//  Network News
//
//  Created by David Schweinsberg on 6/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ContentType.h"


@implementation ContentType

@synthesize mediaType;
@synthesize charset;
@synthesize format;

- (id)initWithString:(NSString *)string
{
    self = [super init];
    if (self)
    {
        NSArray *components = [string componentsSeparatedByString:@";"];
        self.mediaType = [components objectAtIndex:0];
        
        if (components.count > 1)
        {
            NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@" \""];
            
            // Parse any parameters
            for (NSUInteger i = 1; i < components.count; ++i)
            {
                NSArray *paramComponents = [[components objectAtIndex:i] componentsSeparatedByString:@"="];
                if (paramComponents.count == 2)
                {
                    NSString *name = [paramComponents objectAtIndex:0];
                    NSString *value = [paramComponents objectAtIndex:1];
                    
                    name = [name stringByTrimmingCharactersInSet:set];
                    value = [value stringByTrimmingCharactersInSet:set];
                    
                    if ([name caseInsensitiveCompare:@"charset"] == NSOrderedSame)
                        self.charset = value.lowercaseString;
                    else if ([name caseInsensitiveCompare:@"format"] == NSOrderedSame)
                        self.format = value.lowercaseString;
                }
            }
        }
    }
    return self;
}

- (BOOL)isFormatFlowed
{
    return [format isEqualToString:@"flowed"];
}

@end
