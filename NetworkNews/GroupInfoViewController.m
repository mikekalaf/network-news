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

- (id)init
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

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark -
#pragma mark Actions

- (void)doneButtonPressed:(id)sender
{
    [delegate closedGroupInfoController:self];
}

@end
