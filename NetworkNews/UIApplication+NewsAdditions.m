//
//  UIApplication+NewsAdditions.m
//  NetworkNews
//
//  Created by David Schweinsberg on 24/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "UIApplication+NewsAdditions.h"

static NSInteger __count = 0;

@implementation UIApplication (NewsAdditions)

- (void)showNetworkActivityIndicator {
  @synchronized([UIApplication sharedApplication]) {
    if (__count == 0)
      dispatch_async(dispatch_get_main_queue(), ^{
        [self setNetworkActivityIndicatorVisible:YES];
      });
    ++__count;
  }
}

- (void)hideNetworkActivityIndicator {
  @synchronized([UIApplication sharedApplication]) {
    --__count;
    if (__count <= 0) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self setNetworkActivityIndicatorVisible:NO];
      });
      __count = 0;
    }
  }
}

@end
