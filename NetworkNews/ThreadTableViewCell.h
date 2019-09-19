//
//  ThreadTableViewCell.h
//  Network News
//
//  Created by David Schweinsberg on 9/06/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThreadTableViewCell : UITableViewCell {
  UILabel *dateLabel;
}

@property(nonatomic, retain, readonly) UILabel *dateLabel;

@end
