//
//  Preferences.m
//  Network News
//
//  Created by David Schweinsberg on 16/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "Preferences.h"

NSString *NewsQuoteLevel1ColorKey = @"NewsQuoteLevel1Color";
NSString *NewsQuoteLevel2ColorKey = @"NewsQuoteLevel2Color";
NSString *NewsQuoteLevel3ColorKey = @"NewsQuoteLevel3Color";

@implementation Preferences

+ (void)registerDefaults {
  NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
  UIColor *color;

  // Level 1 - Blue
  color = [UIColor colorWithRed:0.027450
                          green:0.349019
                           blue:0.764705
                          alpha:1.0];
  defaultValues[NewsQuoteLevel1ColorKey] =
      [NSKeyedArchiver archivedDataWithRootObject:color];

  // Level 2 - Green
  color = [UIColor colorWithRed:0.0 green:0.482352 blue:0.0 alpha:1.0];
  defaultValues[NewsQuoteLevel2ColorKey] =
      [NSKeyedArchiver archivedDataWithRootObject:color];

  // Level 3 - Red
  color = [UIColor colorWithRed:0.45 green:0.0 blue:0.0 alpha:1.0];
  defaultValues[NewsQuoteLevel3ColorKey] =
      [NSKeyedArchiver archivedDataWithRootObject:color];

  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

+ (UIColor *)colorForQuoteLevel:(NSUInteger)level {
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSData *data = nil;

  if (level > 3) {
    level %= 3;
    ++level;
  }

  if (level == 0)
    return [UIColor blackColor];
  else if (level == 1)
    data = [userDefaults dataForKey:NewsQuoteLevel1ColorKey];
  else if (level == 2)
    data = [userDefaults dataForKey:NewsQuoteLevel2ColorKey];
  else
    data = [userDefaults dataForKey:NewsQuoteLevel3ColorKey];

  if (data)
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
  else
    return nil;
}

@end
