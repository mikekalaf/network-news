//
//  EmailAddressFormatter.m
//  Network News
//
//  Created by David Schweinsberg on 21/12/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import "EmailAddressFormatter.h"

static NSCharacterSet *characterSet;
static NSCharacterSet *trimCharacterSet;

@implementation EmailAddressFormatter

+ (void)initialize
{
    characterSet = [NSCharacterSet characterSetWithCharactersInString:@"<>()"];
    trimCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" \""];
}

- (NSString *)stringForObjectValue:(id)obj
{
    if ([obj isKindOfClass:[NSString class]])
    {
        NSString *string = obj;

        NSArray *components = [string componentsSeparatedByCharactersInSet:characterSet];
        //NSLog(@"components: %@", components.description);

        NSInteger index = 0;
        NSInteger addressIndex = NSNotFound;
        for (NSString *substr in components)
        {
            if ([substr rangeOfString:@"@"].location != NSNotFound)
            {
                // email address
                addressIndex = index;
                break;
            }
            ++index;
        }
        
        if (addressIndex > 0)
        {
            // Use the text preceeding the email address as the name
            string = [components[0] stringByTrimmingCharactersInSet:trimCharacterSet];
        }
        else if (addressIndex == 0 && components.count > 1)
        {
            // Use the text following the email address as the name
            string = [components[1] stringByTrimmingCharactersInSet:trimCharacterSet];
        }

        if ([string isEqualToString:@""])
        {
            if (addressIndex != NSNotFound)
            {
                // Use the email address as the name
                string = components[addressIndex];
            }
            else
            {
                // Find the first non-empty component
                for (NSString *substr in components)
                {
                    if ([substr isEqualToString:@""] == NO)
                    {
                        string = [substr stringByTrimmingCharactersInSet:trimCharacterSet];
                        break;
                    }
                }
            }
        }
        
        return string;
    }
    return nil;
}

- (BOOL)getObjectValue:(id *)obj
             forString:(NSString *)string
      errorDescription:(NSString **)errorString
{
    *obj = nil;
    return YES;
}

@end
