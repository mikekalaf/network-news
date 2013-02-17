//
//  ThreadListTableViewCell.h
//  Network News
//
//  Created by David Schweinsberg on 9/06/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ThreadListTableViewCell : UITableViewCell
{
    UILabel *dateLabel;
    UILabel *threadCountLabel;
}

@property(nonatomic, retain, readonly) UILabel *dateLabel;
@property(nonatomic, retain, readonly) UILabel *threadCountLabel;

@end
