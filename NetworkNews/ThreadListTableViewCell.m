//
//  ThreadListTableViewCell.m
//  Network News
//
//  Created by David Schweinsberg on 9/06/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ThreadListTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@interface ThreadListTableViewCell (Private)

- (void)colorAsSelected:(BOOL)selected;

@end


@implementation ThreadListTableViewCell

@synthesize dateLabel;
@synthesize threadCountLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
        [[self detailTextLabel] setTextColor:[UIColor blackColor]];
        [[self detailTextLabel] setNumberOfLines:3];

        // Add a label to display the date
        dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [dateLabel setFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
        [[self contentView] addSubview:dateLabel];
        
        // Add a label to display the thread count
        threadCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [threadCountLabel setTextAlignment:NSTextAlignmentCenter];
        [threadCountLabel setFont:[UIFont boldSystemFontOfSize:12]];
        [[threadCountLabel layer] setCornerRadius:4];
        [[self contentView] addSubview:threadCountLabel];
        
        [self colorAsSelected:NO];
    }
    return self;
}

- (void)colorAsSelected:(BOOL)selected
{
    if (selected)
    {
        [dateLabel setTextColor:[UIColor whiteColor]];
        [threadCountLabel setBackgroundColor:[UIColor whiteColor]];
        [threadCountLabel setTextColor:[UIColor blueColor]];
    }
    else
    {
        [dateLabel setTextColor:[UIColor blueColor]];
        [threadCountLabel setBackgroundColor:[UIColor grayColor]];
        [threadCountLabel setTextColor:[UIColor whiteColor]];
    }
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
    
    CGSize contentSize = [[self contentView] frame].size;

    // Size the date label to fit the content
    [dateLabel sizeToFit];
    CGRect dateFrame = [dateLabel frame];

    // Position the main text at the top of the cell
    CGRect textFrame = [[self textLabel] frame];
    textFrame.origin.y = 2;
    textFrame.size.width = contentSize.width - textFrame.origin.x - dateFrame.size.width - 12;
    [[self textLabel] setFrame:textFrame];
    
    // Position the date label
    dateFrame.origin.x = contentSize.width - dateFrame.size.width - 8;
    dateFrame.origin.y = 2 + (textFrame.size.height - dateFrame.size.height);
    [dateLabel setFrame:dateFrame];
    
    // Position the thread-count label
    [threadCountLabel sizeToFit];
    CGRect frame = [threadCountLabel frame];
    frame.origin.x = contentSize.width - 25;
    frame.origin.y = (int)(contentSize.height / 2 - 8);
    frame.size.width = MAX(frame.size.width, 20);
    frame.size.height = 17;
    [threadCountLabel setFrame:frame];

    // Shorten the detail text label so it doesn't overwrite the thread-count label
    CGRect detailTextFrame = [[self detailTextLabel] frame];
    detailTextFrame.size.width = contentSize.width - detailTextFrame.origin.x - frame.size.width - 12;
    [[self detailTextLabel] setFrame:detailTextFrame];
}

@end
