// 
//  Article.m
//  Network News
//
//  Created by David Schweinsberg on 10/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "Article.h"
#import "ArticlePart.h"

@implementation Article 

@dynamic date;
@dynamic from;
@dynamic subject;
@dynamic totalByteCount;
@dynamic totalLineCount;
@dynamic completePartCount;
@dynamic references;
@dynamic attachmentFileName;

@dynamic parts;

+ (NSDate *)dateWithString:(NSString *)dateString
{
    static NSDateFormatter *dateFormatter1;
    static NSDateFormatter *dateFormatter2;
    static NSDateFormatter *dateFormatter3;
    if (dateFormatter1 == nil)
    {
        dateFormatter1 = [[NSDateFormatter alloc] init];
        [dateFormatter1 setDateFormat:@"dd MMM yyyy HH:mm:ss Z"];
        
        dateFormatter2 = [[NSDateFormatter alloc] init];
        [dateFormatter2 setDateFormat:@"dd MMM yyyy HH:mm:ss zzz"];
        
        dateFormatter3 = [[NSDateFormatter alloc] init];
        [dateFormatter3 setDateFormat:@"dd MMM yyyy HH:mm:ss"];
    }
    
    NSRange range = NSMakeRange(0, dateString.length);
    
    // Trim any trailing comment
    if ([dateString hasSuffix:@")"])
    {
        for (NSUInteger i = 0; i < range.length; ++i)
            if ([dateString characterAtIndex:range.length - i - 1] == L'(')
            {
                if ([dateString characterAtIndex:range.length - i - 2] == L' ')
                    range.length -= (i + 1);
                else
                    range.length -= i;
                break;
            }
    }
    
    // Trim the leading day if it exists
    for (NSUInteger i = 0; i < range.length; ++i)
        if ([dateString characterAtIndex:i] == ',')
        {
            if ([dateString characterAtIndex:i + 1] == ' ')
                i += 2;
            else
                ++i;
            range.location = i;
            range.length -= i;
            break;
        }
    
    NSString *str = [dateString substringWithRange:range];
    NSDate *date = [dateFormatter1 dateFromString:str];
    if (date == nil)
        date = [dateFormatter2 dateFromString:str];
    if (date == nil)
        date = [dateFormatter3 dateFromString:str];
    
    if (date == nil)
    {
        NSLog(@"Unable to parse date string: %@", str);
    }
    
    return date;
}

- (NSArray *)messageIds
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.parts.count];
    for (ArticlePart *part in self.parts)
        [array addObject:part.messageId];
    return array;
}

- (NSString *)firstMessageId
{
    for (ArticlePart *part in self.parts)
        if (part.partNumber.integerValue == 1)
            return part.messageId;
    return nil;
}

//- (NSDate *)firstDate
//{
//    NSInteger earliestPart = NSIntegerMax;
//    NSDate *earliestDate = nil;
//    for (ArticlePart *part in self.parts)
//    {
//        NSInteger partNumber = part.partNumber.integerValue;
//        if (partNumber == 1)
//            return part.date;
//        else if (partNumber < earliestPart)
//        {
//            earliestPart = partNumber;
//            earliestDate = part.date;
//        }
//    }
//    return earliestDate;
//}

- (BOOL)hasAllParts
{
    return self.parts.count == self.completePartCount.integerValue;
}

- (NSString *)reSubject
{
    if ([self.subject hasPrefix:@"Re: "])
        return self.subject;
    else if ([self.subject hasPrefix:@"Re:"])
        return self.subject;
    else
        return [NSString stringWithFormat:@"Re: %@", self.subject];
}

@end
