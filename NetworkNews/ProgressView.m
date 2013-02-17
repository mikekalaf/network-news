//
//  ProgressView.m
//  Network News
//
//  Created by David Schweinsberg on 17/06/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ProgressView.h"

#define TEXT_Y_OFFSET 1

@implementation ProgressView

@synthesize updatedDate;

- (id)init
{
    self = [super initWithFrame:CGRectMake(0, 0, 200, 20)];
    if (self)
    {
    }
    return self;
}

#pragma mark -
#pragma mark Private Methods

- (void)checkingStatus
{
    for (UIView *subview in self.subviews)
        [subview removeFromSuperview];

    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self addSubview:activityIndicatorView];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self addSubview:label];

    // Generate the text
    NSString *text = @" Checking for News...";
    
    // The font we're going to use
    UIFont *boldFont = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
    
    // Determine the sizes
    CGSize size1 = activityIndicatorView.frame.size;
    CGSize size2 = [text sizeWithFont:boldFont];
    
    // Do the layout
    float totalWidth = size1.width + size2.width;
    float xOffset = (int)((self.frame.size.width - totalWidth) / 2);
    activityIndicatorView.frame = CGRectMake(xOffset, 0, size1.width, size1.height);
    label.frame = CGRectMake(xOffset + size1.width, TEXT_Y_OFFSET, size2.width, size2.height);

    label.opaque = NO;
    label.backgroundColor = nil;
    label.shadowColor = [UIColor grayColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
    label.text = text;

    [activityIndicatorView startAnimating];
}

- (void)updatedStatus
{
    for (UIView *subview in self.subviews)
        [subview removeFromSuperview];

    // Create the labels
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self addSubview:label1];
    UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self addSubview:label2];
    
    // Generate the text
    NSString *text1 = @"Updated ";

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    NSString *text2 = [dateFormatter stringFromDate:updatedDate];

    // The fonts we're going to use
    UIFont *normalFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    UIFont *boldFont = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];

    // Determine the sizes
    CGSize size1 = [text1 sizeWithFont:boldFont];
    CGSize size2 = [text2 sizeWithFont:normalFont];

    // Do the layout
    float totalWidth = size1.width + size2.width;
    float xOffset = (int)((self.frame.size.width - totalWidth) / 2);
    label1.frame = CGRectMake(xOffset, TEXT_Y_OFFSET, size1.width, size1.height);
    label2.frame = CGRectMake(xOffset + size1.width, TEXT_Y_OFFSET, size2.width, size2.height);
    
    // Configure the labels
    label1.opaque = NO;
    label1.backgroundColor = nil;
    label1.shadowColor = [UIColor grayColor];
    label1.textColor = [UIColor whiteColor];
    label1.font = boldFont;
    label1.text = text1;
    
    label2.opaque = NO;
    label2.backgroundColor = nil;
    label2.shadowColor = [UIColor grayColor];
    label2.textColor = [UIColor whiteColor];
    label2.font = normalFont;
    label2.text = text2;
}

#pragma mark -
#pragma mark Properties

- (ProgressViewStatus)status
{
    return status;
}

- (void)setStatus:(ProgressViewStatus)aStatus
{
    if (status != aStatus)
    {
        status = aStatus;

        if (status == ProgressViewStatusChecking)
            [self checkingStatus];
        else if (status == ProgressViewStatusUpdated)
            [self updatedStatus];
    }
}

@end
