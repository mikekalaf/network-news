//
//  ProgressView.h
//  Network News
//
//  Created by David Schweinsberg on 17/06/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

enum
{
    ProgressViewStatusChecking,
    ProgressViewStatusUpdated
};
typedef NSUInteger ProgressViewStatus;

@interface ProgressView : UIView
{
    ProgressViewStatus status;
    NSDate *updatedDate;
}

@property(nonatomic) ProgressViewStatus status;
@property(nonatomic, retain) NSDate *updatedDate;

@end
