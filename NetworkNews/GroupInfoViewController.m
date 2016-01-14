//
//  GroupInfoViewController.m
//  Network News
//
//  Created by David Schweinsberg on 4/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "GroupInfoViewController.h"


@implementation GroupInfoViewController

@synthesize delegate;

- (instancetype)init
{
    self = [super initWithNibName:@"GroupInfoView" bundle:nil];
    if (self)
    {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *doneButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                  target:self
                                                  action:@selector(doneButtonPressed:)];
    self.navigationItem.rightBarButtonItem = doneButtonItem;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark -
#pragma mark Actions

- (void)doneButtonPressed:(id)sender
{
    [delegate closedGroupInfoController:self];
}

@end
