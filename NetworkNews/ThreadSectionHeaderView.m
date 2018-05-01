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

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];

        _textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _textLabel.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
        _textLabel.textColor = UIColor.blackColor;
        [self addSubview:_textLabel];

        _dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _dateLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        _dateLabel.textColor = UIColor.blackColor;
        [self addSubview:_dateLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    const int kLeftMargin = 33;
    const int kRightMargin = 28;
    CGRect bounds = self.bounds;

    [_dateLabel sizeToFit];
    CGFloat dateWidth = _dateLabel.frame.size.width + kRightMargin;
    
    CGRect textFrame = CGRectMake(kLeftMargin,
                                  0,
                                  bounds.size.width - dateWidth - kLeftMargin,
                                  bounds.size.height);
    _textLabel.frame = textFrame;

    CGRect dateFrame = CGRectMake(bounds.size.width - dateWidth,
                                  0,
                                  bounds.size.width,
                                  bounds.size.height);
    _dateLabel.frame = dateFrame;
}

@end
