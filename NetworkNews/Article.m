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

+ (NSDate *)dateWithString:(NSString *)dateString {
  //    NSLog(@"Date: %@", dateString);

  //    NSString *pattern =
  //    @"^(\\w{3}|),?\\s*"               // 1. Name of day
  //    @"(\\d+)\\s*"                     // 2. Day
  //    @"(\\w{3})\\s*"                   // 3. Name of month
  //    @"(\\d{2}|\\d{4})\\s*"            // 4. Year
  //    @"(\\d{2}):(\\d{2}):(\\d{2})\\s*" // 5/6/7. hh:mm:ss
  //    @"([\\+|-]\\d{4}|\\w+)";          // 8. Time zone
  //    NSError *error = nil;
  //    NSRegularExpression *regex =
  //    [NSRegularExpression regularExpressionWithPattern:pattern
  //                                              options:NSRegularExpressionCaseInsensitive
  //                                                error:&error];
  //    NSTextCheckingResult *match = [regex firstMatchInString:dateString
  //                                                    options:0
  //                                                      range:NSMakeRange(0,
  //                                                      dateString.length)];
  //    if (match.range.location != NSNotFound)
  //    {
  //        for (NSUInteger i = 0; i < match.numberOfRanges; ++i)
  //        {
  //            NSRange range = [match rangeAtIndex:i];
  //            NSString *group = [dateString substringWithRange:range];
  //            NSLog(@"group %lu: %@", i, group);
  //        }
  //
  //        NSInteger day = [dateString substringWithRange:[match
  //        rangeAtIndex:2]].integerValue; NSInteger month = [dateString
  //        substringWithRange:[match rangeAtIndex:3]].integerValue; NSInteger
  //        year = [dateString substringWithRange:[match
  //        rangeAtIndex:4]].integerValue; if (year < 100)
  //            year += 2000;
  //        NSInteger hour = [dateString substringWithRange:[match
  //        rangeAtIndex:5]].integerValue; NSInteger minute = [dateString
  //        substringWithRange:[match rangeAtIndex:6]].integerValue; NSInteger
  //        second = [dateString substringWithRange:[match
  //        rangeAtIndex:7]].integerValue; NSString *tz = [dateString
  //        substringWithRange:[match rangeAtIndex:8]]; unichar tzPrefix = [tz
  //        characterAtIndex:0]; if (tzPrefix == '+' || tzPrefix == '-')
  //    }
  //    else
  //    {
  //        NSLog(@"Date not found");
  //    }

  static NSDateFormatter *dateFormatter1;
  static NSDateFormatter *dateFormatter2;
  static NSDateFormatter *dateFormatter3;
  if (dateFormatter1 == nil) {
    dateFormatter1 = [[NSDateFormatter alloc] init];
    dateFormatter1.dateFormat = @"dd MMM yyyy HH:mm:ss Z";

    dateFormatter2 = [[NSDateFormatter alloc] init];
    dateFormatter2.dateFormat = @"dd MMM yyyy HH:mm:ss zzz";

    dateFormatter3 = [[NSDateFormatter alloc] init];
    dateFormatter3.dateFormat = @"dd MMM yyyy HH:mm:ss";
  }

  NSRange range = NSMakeRange(0, dateString.length);

  // Trim any trailing comment
  if ([dateString hasSuffix:@")"]) {
    for (NSUInteger i = 0; i < range.length; ++i)
      if ([dateString characterAtIndex:range.length - i - 1] == L'(') {
        if ([dateString characterAtIndex:range.length - i - 2] == L' ')
          range.length -= (i + 1);
        else
          range.length -= i;
        break;
      }
  }

  // Trim the leading day if it exists
  for (NSUInteger i = 0; i < range.length; ++i)
    if ([dateString characterAtIndex:i] == ',') {
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
  if (date == nil) {
    // Strip off any stray time zone designator
    str = [str
        stringByTrimmingCharactersInSet:[NSCharacterSet letterCharacterSet]];
    date = [dateFormatter3 dateFromString:str];
  }

  if (date == nil) {
    NSLog(@"Unable to parse date string: %@", str);
  }

  return date;
}

- (NSArray *)messageIds {
  NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.parts.count];
  for (ArticlePart *part in self.parts)
    [array addObject:part.messageId];
  return array;
}

- (NSString *)firstMessageId {
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

- (BOOL)hasAllParts {
  return self.parts.count == self.completePartCount.integerValue;
}

- (NSString *)reSubject {
  if ([self.subject hasPrefix:@"Re: "])
    return self.subject;
  else if ([self.subject hasPrefix:@"Re:"])
    return self.subject;
  else
    return [NSString stringWithFormat:@"Re: %@", self.subject];
}

@end
