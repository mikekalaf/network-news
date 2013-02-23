//
//  ThreadViewController.h
//  Network News
//
//  Created by David Schweinsberg on 21/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ArticleViewController.h"

@interface ThreadViewController : UITableViewController <ArticleSource>
{
    NSArray *articles;
    NSString *threadTitle;
    NSDate *threadDate;
    NSString *groupName;
    NSDateFormatter *dateFormatter;
    NSFormatter *emailAddressFormatter;
    UIImage *unreadIconImage;
    UIImage *readIconImage;
    UIImage *incompleteIconImage;
}

- (id)initWithArticles:(NSArray *)articleArray
           threadTitle:(NSString *)aThreadTitle
            threadDate:(NSDate *)aThreadDate
             groupName:(NSString *)aGroupName;

- (void)returningFromArticleIndex:(NSUInteger)fromArticleIndex;

@end
