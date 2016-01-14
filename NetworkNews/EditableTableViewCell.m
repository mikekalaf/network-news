//
//  EditableTableViewCell.m
//  Network News
//
//  Created by David Schweinsberg on 1/09/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "EditableTableViewCell.h"


@implementation EditableTableViewCell

@synthesize textField;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        textField = [[UITextField alloc] initWithFrame:CGRectZero];
        textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        [self.contentView addSubview:textField];
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

//    [textField becomeFirstResponder];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
//    [textField becomeFirstResponder];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize contentSize = self.contentView.frame.size;
    
    CGRect frame = self.textLabel.frame;
    frame.size.width = 100;
    self.textLabel.frame = frame;
    
    float x = frame.origin.x + frame.size.width;
    textField.frame = CGRectMake(x, 0, contentSize.width - x - 10, contentSize.height);
}


@end
