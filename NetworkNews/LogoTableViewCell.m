//
//  LogoTableViewCell.m
//  Network News
//
//  Created by David Schweinsberg on 3/09/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "LogoTableViewCell.h"


@implementation LogoTableViewCell

//- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
//    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
//        // Initialization code
//    }
//    return self;
//}
//
//
//- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//
//    [super setSelected:selected animated:animated];
//
//    // Configure the view for the selected state
//}
//
//
//- (void)dealloc {
//    [super dealloc];
//}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Centre the image view
    CGSize contentSize = self.contentView.frame.size;
    CGRect imageFrame = self.imageView.frame;
    imageFrame.origin.x = contentSize.width / 2 - imageFrame.size.width / 2;
    self.imageView.frame = imageFrame;
}

@end
