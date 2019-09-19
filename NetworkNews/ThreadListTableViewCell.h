//
//  ThreadListTableViewCell.h
//  Network News
//
//  Created by David Schweinsberg on 9/06/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThreadListTableViewCell : UITableViewCell {
}

@property(nonatomic) IBOutlet UIImageView *readStatusImage;
@property(nonatomic) IBOutlet UILabel *titleLabel;
@property(nonatomic) IBOutlet UILabel *previewLabel;
@property(nonatomic) IBOutlet UILabel *dateLabel;

@end
