//
//  ThreadTableViewCell.m
//  Network News
//
//  Created by David Schweinsberg on 9/06/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ThreadTableViewCell.h"

@implementation ThreadTableViewCell

@synthesize dateLabel;

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
  if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
    // Add a label display the date
    CGRect frame = CGRectMake(200, 4, 96, 16);
    dateLabel = [[UILabel alloc] initWithFrame:frame];
    dateLabel.textColor = [UIColor blueColor];
    dateLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    [self.contentView addSubview:dateLabel];
  }
  return self;
}

//- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//
//    [super setSelected:selected animated:animated];
//
//    // Configure the view for the selected state
//}
//

- (void)layoutSubviews {
  [super layoutSubviews];

  CGFloat contentWidth = self.contentView.frame.size.width;

  // Size the date label to fit the content, and align it to the right
  [dateLabel sizeToFit];
  CGRect dateFrame = dateLabel.frame;
  dateFrame.origin.x = contentWidth - dateFrame.size.width - 8;
  dateLabel.frame = dateFrame;

  // Shorten the text label so it doesn't overwrite the date label
  CGRect textFrame = self.textLabel.frame;
  textFrame.size.width =
      contentWidth - textFrame.origin.x - dateFrame.size.width - 12;
  self.textLabel.frame = textFrame;
}

@end
