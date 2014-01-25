//
//  Article.h
//  Network News
//
//  Created by David Schweinsberg on 10/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ArticlePart;

/**
 * Corresponds to one or more messages on the news server. In a simple case,
 * involving a regular text news article, there will be a single Article with a
 * single ArticlePart referenced. If the actual article is split over multple
 * articles on the server, then there will be a single Article, and multiple
 * ArticleParts referenced.
 *
 * We're keeping references as a string of message ids because it may be
 * referring to messages that are not present in our database.
 */
@interface Article :  NSManagedObject  
{
}

@property(nonatomic, retain) NSDate *date;
@property(nonatomic, retain) NSString *from;
@property(nonatomic, retain) NSString *subject;
@property(nonatomic, retain) NSNumber *totalByteCount;
@property(nonatomic, retain) NSNumber *totalLineCount;
@property(nonatomic, retain) NSNumber *completePartCount;
@property(nonatomic, retain) NSString *references;
@property(nonatomic, retain) NSString *attachmentFileName;

@property(nonatomic, retain) NSSet *parts;

@property(nonatomic, retain, readonly) NSArray *messageIds;
@property(nonatomic, retain, readonly) NSString *firstMessageId;
@property(nonatomic, readonly) BOOL hasAllParts;
@property(nonatomic, retain, readonly) NSString *reSubject;

+ (NSDate *)dateWithString:(NSString *)dateString;


@end


@interface Article (CoreDataGeneratedAccessors)
- (void)addPartsObject:(ArticlePart *)value;
- (void)removePartsObject:(ArticlePart *)value;
- (void)addParts:(NSSet *)value;
- (void)removeParts:(NSSet *)value;

@end
