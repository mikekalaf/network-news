//
//  UIColor+NewsAdditions.m
//  NetworkNews
//
//  Created by David Schweinsberg on 5/04/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "UIColor+NewsAdditions.h"

@implementation UIColor (NewsAdditions)

+ (UIColor *)toolbarTextColor
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        return [UIColor colorWithRed:0.443 green:0.47 blue:0.5 alpha:1.0];
    }
    else
    {
        return [UIColor blackColor];
    }
}

@end
