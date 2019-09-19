//
//  NewArticleViewController.h
//  Network News
//
//  Created by David Schweinsberg on 25/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NewArticleViewController;
@protocol NewArticleDelegate;
@class NewsConnectionPool;

@interface NewArticleViewController : UIViewController {
}

@property(nonatomic) NewsConnectionPool *connectionPool;
@property(nonatomic, weak) id<NewArticleDelegate> delegate;

- (void)setGroupName:(NSString *)groupName;
- (void)setSubject:(NSString *)subject;
- (void)setReferences:(NSString *)references;
- (void)setMessageBody:(NSString *)messageBody;

- (IBAction)cancelButtonPressed:(id)sender;

- (IBAction)sendButtonPressed:(id)sender;

@end

@protocol NewArticleDelegate

- (void)newArticleViewController:(NewArticleViewController *)controller
                         didSend:(BOOL)send;

@end
