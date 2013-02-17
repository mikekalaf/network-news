//
//  NewArticleViewController.h
//  Network News
//
//  Created by David Schweinsberg on 25/04/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NewArticleViewController;
@class Task;
@protocol NewArticleDelegate;

@interface NewArticleViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate>
{
    UITextView *textView;
    UIView *toView;
    UIView *subjectView;
    UILabel *toLabel;
    UITextField *subjectTextField;
    UIBarButtonItem *cancelButtonItem;
    UIBarButtonItem *sendButtonItem;
    UIActivityIndicatorView *activityIndicatorView;
    id <NewArticleDelegate> delegate;
    Task *currentTask;
    NSString *groupName;
    NSString *subject;
    NSString *references;
    NSString *bodyText;
    BOOL keyboardShown;
    BOOL restoringText;
    NSRange restoredSelectedRange;
}

@property(nonatomic, retain) IBOutlet UITextView *textView;
@property(nonatomic, retain) IBOutlet UIView *toView;
@property(nonatomic, retain) IBOutlet UIView *subjectView;
@property(nonatomic, retain) IBOutlet UILabel *toLabel;
@property(nonatomic, retain) IBOutlet UITextField *subjectTextField;
@property(nonatomic, retain) id <NewArticleDelegate> delegate;

- (id)initWithGroupName:(NSString *)aGroupName
                subject:(NSString *)aSubject
             references:(NSString *)aReferences
               bodyText:(NSString *)aBodyText;

- (void)restoreLevel;

- (IBAction)cancelButtonPressed:(id)sender;

- (IBAction)sendButtonPressed:(id)sender;

@end

@protocol NewArticleDelegate

- (void)newArticleViewController:(NewArticleViewController *)controller
                         didSend:(BOOL)send;

@end
