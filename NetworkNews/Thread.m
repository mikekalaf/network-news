//
//  Thread.m
//  Network News
//
//  Created by David Schweinsberg on 20/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "Thread.h"
#import "Article.h"
//#import "NetworkNewsAppDelegate.h"
#import "CoreDataStore.h"

@implementation Thread

@synthesize subject;
@synthesize initialAuthor;
@synthesize earliestDate;
@synthesize latestDate;
@synthesize articles;
@synthesize sorted;
@synthesize messageID;
@synthesize threadType;

- (id)init
{
    self = [super init];
    if (self)
    {
        articles = [[NSMutableArray alloc] initWithCapacity:1];
        sorted = YES;
    }
    return self;
}

- (id)initWithArticle:(Article *)article
{
    self = [self init];
    if (self)
    {
        self.subject = article.subject;
        self.latestDate = article.date;
        [articles addObject:article];
    }
    return self;
}

//- (id)initWithCoder:(NSCoder *)aDecoder
//{
//    self = [self init];
//    if (self)
//    {
//        self.subject = [aDecoder decodeObjectForKey:@"Subject"];
//        self.latestDate = [aDecoder decodeObjectForKey:@"LatestDate"];
//        
//        NetworkNewsAppDelegate *appDelegate = (NetworkNewsAppDelegate *)[[UIApplication sharedApplication] delegate];
//        NSManagedObjectContext *context = appDelegate.activeCoreDataStack.managedObjectContext;
//        NSPersistentStoreCoordinator *storeCoord = appDelegate.activeCoreDataStack.persistentStoreCoordinator;
//        
//        NSArray *array = [aDecoder decodeObjectForKey:@"Articles"];
//        for (NSURL *articleURI in array)
//        {
//            NSManagedObjectID *objectID = [storeCoord managedObjectIDForURIRepresentation:articleURI];
//            if (objectID == nil)
//            {
//                [self release];
//                return nil;
//            }
//            [articles addObject:[context objectWithID:objectID]];
//        }
//    }
//    return self;
//}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:subject forKey:@"Subject"];
    [aCoder encodeObject:latestDate forKey:@"LatestDate"];
    
    // Build an array of all the article coredata URIs, and encode the array
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:articles.count];
    for (Article *article in articles)
        [array addObject:article.objectID.URIRepresentation];
    [aCoder encodeObject:array forKey:@"Articles"];
}

#pragma mark -
#pragma mark Properties

- (NSArray *)sortedArticles
{
    if (!sorted)
        return articles;

    if (sortedArticles == nil)
    {
        // Sort the articles in the thread in ascending date order
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date"
                                                                       ascending:YES];
        
        sortedArticles = [articles sortedArrayUsingDescriptors:
                          [NSArray arrayWithObject:sortDescriptor]];
    }
    return sortedArticles;
}

- (ReadStatus)readStatus
{
    NSUInteger readCount = 0;
    for (Article *article in articles)
        if (article.read.boolValue)
            ++readCount;
    if (readCount == 0)
        return ReadStatusUnread;
    else if (readCount < articles.count)
        return ReadStatusPartiallyRead;
    else
        return ReadStatusRead;
}

- (BOOL)hasAllParts
{
    for (Article *article in articles)
        if (![article hasAllParts])
            return NO;
    return YES;
}

@end
