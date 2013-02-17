//
//  ThreadSectionHeaderView.m
//  Network News
//
//  Created by David Schweinsberg on 16/02/11.
//  Copyright 2011 David Schweinsberg. All rights reserved.
//

#import "ThreadSectionHeaderView.h"
#import <QuartzCore/QuartzCore.h>

@implementation ThreadSectionHeaderView

@synthesize textLabel;
@synthesize dateLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setUserInteractionEnabled:NO];
        [self setOpaque:NO];
        
        gradientLayer = [CAGradientLayer layer];
        [gradientLayer setColors:[NSArray arrayWithObjects:
                                  (id)[[UIColor colorWithRed:0.505 green:0.556 blue:0.596 alpha:0.9] CGColor],
                                  (id)[[UIColor colorWithRed:0.670 green:0.705 blue:0.733 alpha:0.9] CGColor],
//                                  (id)[[UIColor colorWithRed:0.529 green:0.553 blue:0.572 alpha:0.5] CGColor],
//                                  (id)[[UIColor colorWithRed:0.592 green:0.635 blue:0.670 alpha:0.5] CGColor],
                                  nil]];
        [[self layer] insertSublayer:gradientLayer atIndex:0];
        
        textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [textLabel setFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]];
        [textLabel setTextColor:[UIColor whiteColor]];
        [textLabel setShadowOffset:CGSizeMake(0, 1)];
        [textLabel setShadowColor:[UIColor colorWithRed:0.427 green:0.427 blue:0.427 alpha:1.0]];
        [textLabel setBackgroundColor:[UIColor clearColor]];
        [textLabel setOpaque:NO];
        [self addSubview:textLabel];

        dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [dateLabel setFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
        [dateLabel setTextColor:[UIColor whiteColor]];
        [dateLabel setShadowOffset:CGSizeMake(0, 1)];
        [dateLabel setShadowColor:[UIColor colorWithRed:0.427 green:0.427 blue:0.427 alpha:1.0]];
        [dateLabel setBackgroundColor:[UIColor clearColor]];
        [dateLabel setOpaque:NO];
        [self addSubview:dateLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    const int kLeftMargin = 33;
    const int kRightMargin = 28;
    CGRect bounds = [self bounds];
    [gradientLayer setFrame:bounds];

    [dateLabel sizeToFit];
    CGFloat dateWidth = [dateLabel frame].size.width + kRightMargin;
    
    CGRect textFrame = CGRectMake(kLeftMargin,
                                  0,
                                  bounds.size.width - dateWidth - kLeftMargin,
                                  bounds.size.height);
    [textLabel setFrame:textFrame];

    CGRect dateFrame = CGRectMake(bounds.size.width - dateWidth,
                                  0,
                                  bounds.size.width,
                                  bounds.size.height);
    [dateLabel setFrame:dateFrame];
}

@end
