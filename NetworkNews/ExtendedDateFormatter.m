//
//  ExtendedDateFormatter.m
//  Network News
//
//  Created by David Schweinsberg on 26/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ExtendedDateFormatter.h"


@implementation ExtendedDateFormatter

- (NSString *)stringFromDate:(NSDate *)date
{
    NSDate *now = [NSDate date];
    NSTimeInterval timeInterval = now.timeIntervalSinceReferenceDate;
    
    // Adjust for the time zone (GMT to local)
    NSTimeZone *timeZone = [NSTimeZone defaultTimeZone];
    timeInterval += timeZone.secondsFromGMT;
    
    // How many seconds are we into the current day?
    NSUInteger secondsToday = (NSUInteger) timeInterval % 86400;
    
    // Rewind the time interval back to midnight
    timeInterval -= secondsToday;

    // Readjust for the time zone again (back to GMT)
    timeInterval -= timeZone.secondsFromGMT;
    
    NSTimeInterval dateTimeInterval = date.timeIntervalSinceReferenceDate;
    if (timeInterval <= dateTimeInterval && dateTimeInterval < (timeInterval + 86400))
    {
        // Today
        self.dateStyle = NSDateFormatterNoStyle;
        self.timeStyle = NSDateFormatterShortStyle;
    }
    else if ((timeInterval - 86400) <= dateTimeInterval && dateTimeInterval < timeInterval)
    {
        // Yesterday
        return @"Yesterday";
    }
    else if ((timeInterval + 86400) <= dateTimeInterval && dateTimeInterval < (timeInterval + 2 * 86400))
    {
        // Tomorrow
        return @"Tomorrow";
    }
    else if ((timeInterval - 6 * 86400) <= dateTimeInterval && dateTimeInterval < (timeInterval - 86400))
    {
        // Within the last week
        self.dateFormat = @"EEEE";
    }
    else
    {
        self.dateStyle = NSDateFormatterShortStyle;
        self.timeStyle = NSDateFormatterNoStyle;
    }
    
    return [super stringFromDate:date];
}

@end
