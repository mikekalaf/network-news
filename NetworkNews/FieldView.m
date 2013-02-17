//
//  FieldView.m
//  Network News
//
//  Created by David Schweinsberg on 12/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "FieldView.h"


@implementation FieldView


- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGRect bottom = CGRectMake(0, rect.size.height - 1, rect.size.width, 1);
    [[UIColor lightGrayColor] setFill];
    UIRectFill(bottom);
}

@end
