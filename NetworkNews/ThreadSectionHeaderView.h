//
//  ThreadSectionHeaderView.h
//  Network News
//
//  Created by David Schweinsberg on 16/02/11.
//  Copyright 2011 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CAGradientLayer;

@interface ThreadSectionHeaderView : UIView
{
    CAGradientLayer *gradientLayer;
    UILabel *textLabel;
    UILabel *dateLabel;
}

@property(nonatomic, retain) UILabel *textLabel;
@property(nonatomic, retain) UILabel *dateLabel;

@end
