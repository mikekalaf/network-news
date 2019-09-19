//
//  EditableTableViewCell.h
//  Network News
//
//  Created by David Schweinsberg on 1/09/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditableTableViewCell : UITableViewCell {
  UITextField *textField;
}

@property(nonatomic, retain) UITextField *textField;

@end
