//
//  ThreadListTableViewCell.m
//  Network News
//
//  Created by David Schweinsberg on 9/06/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ThreadListTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@interface ThreadListTableViewCell ()

- (void)colorAsSelected:(BOOL)selected;

@end


@implementation ThreadListTableViewCell

@synthesize dateLabel;
@synthesize threadCountLabel;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
        self.detailTextLabel.textColor = [UIColor blackColor];
        self.detailTextLabel.numberOfLines = 3;

        if ([self.reuseIdentifier isEqualToString:@"ThreadCell"])
            self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessory-arrow-2"]];
        else if ([self.reuseIdentifier isEqualToString:@"ArticleCell"])
            self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessory-arrow-1"]];

        [self colorAsSelected:NO];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.detailTextLabel.numberOfLines = 3;

        // Add a label to display the date
        dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        dateLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        dateLabel.textColor = [UIColor lightGrayColor];

        [self.contentView addSubview:dateLabel];
        if ([self.reuseIdentifier isEqualToString:@"ThreadCell"])
            self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessory-arrow-2"]];
        else if ([self.reuseIdentifier isEqualToString:@"ArticleCell"])
            self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessory-arrow-1"]];
    }
    return self;
}

- (void)colorAsSelected:(BOOL)selected
{
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    [self colorAsSelected:highlighted];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self colorAsSelected:selected];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect rect = self.imageView.frame;
    rect.origin.x = 8;
    rect.origin.y = 12;
    self.imageView.frame = rect;

    rect = self.accessoryView.frame;
    rect.origin.y = 12;
    self.accessoryView.frame = rect;

    CGSize contentSize = self.contentView.frame.size;

    // Size the date label to fit the content
    [dateLabel sizeToFit];
    CGRect dateFrame = dateLabel.frame;

    // Position the main text at the top of the cell
    CGRect textFrame = self.textLabel.frame;
    textFrame.origin.y = 2;
    textFrame.size.width = contentSize.width - textFrame.origin.x - dateFrame.size.width - 12;
    self.textLabel.frame = textFrame;
    
    // Position the date label
    dateFrame.origin.x = contentSize.width - dateFrame.size.width - 8;
    dateFrame.origin.y = 2 + (textFrame.size.height - dateFrame.size.height);
    dateLabel.frame = dateFrame;
}

@end
