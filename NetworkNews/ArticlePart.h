//
//  ArticlePart.h
//  Network News
//
//  Created by David Schweinsberg on 19/03/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Article;

/**
 * Corresponds to an individual article on the news server, and thus has a
 * messageId identifying that article.
 */
@interface ArticlePart : NSManagedObject {
}

@property(nonatomic, retain) NSDate *date;
@property(nonatomic, retain) NSNumber *byteCount;
@property(nonatomic, retain) NSString *messageId;
@property(nonatomic, retain) NSNumber *lineCount;
@property(nonatomic, retain) NSNumber *articleNumber;
@property(nonatomic, retain) NSNumber *partNumber;
@property(nonatomic, retain) Article *article;

@end
