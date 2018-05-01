//
//  ActivityView.m
//  NetworkNews
//
//  Created by David Schweinsberg on 4/12/18.
//  Copyright © 2018 David Schweinsberg. All rights reserved.
//

#import "ActivityView.h"

@implementation ActivityView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self internalInit];
    }
    return self;
}

- (void)internalInit
{
    [self setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5]];
    [self setOpaque:NO];

    [[self layer] setCornerRadius:5.0];

    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self addSubview:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
}

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    [self.activityIndicatorView setCenter:CGPointMake(bounds.size.width / 2, bounds.size.height / 2)];
}

@end
