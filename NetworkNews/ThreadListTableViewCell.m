//
//  ThreadListTableViewCell.m
//  Network News
//
//  Created by David Schweinsberg on 9/06/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ThreadListTableViewCell.h"

@interface ThreadListTableViewCell ()

- (void)colorAsSelected:(BOOL)selected;

@end


@implementation ThreadListTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
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

    CGRect rect = self.accessoryView.frame;
    rect.origin.y = 12;
    self.accessoryView.frame = rect;
}

@end
