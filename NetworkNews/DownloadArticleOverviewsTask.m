//
//  DownloadArticleOverviewsTask.m
//  Network News
//
//  Created by David Schweinsberg on 11/12/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import "DownloadArticleOverviewsTask.h"
#import "NNConnection.h"
#import "Article.h"
#import "ArticlePart.h"
#import "Group.h"
#import "LineIterator.h"
#import "EncodedWordDecoder.h"

NSString *ArticleOverviewsDownloadedNotification = @"ArticleOverviewsDownloadedNotification";
NSString *NoSuchGroupNotification = @"NoSuchGroupNotification";

static BOOL PartNumber(NSString *subject,
                       NSInteger *partNumber,
                       NSInteger *totalParts,
                       NSInteger *numberPos,
                       NSUInteger *numberLen)
{
    // Search for the pattern "(n/m)" in the subject string
    
    *partNumber = 0;
    *totalParts = 0;
    
    // Search backwards for the "("
    NSScanner *scanner = nil;
    for (NSInteger i = subject.length - 1; i >= 0; --i)
    {
        if ([subject characterAtIndex:i] == L'(')
        {
            *numberPos = i;

            if (scanner == nil)
                scanner = [[NSScanner alloc] initWithString:subject];
            
            scanner.scanLocation = i + 1;
            if ([scanner scanInteger:partNumber])
            {
                if ([scanner scanString:@"/" intoString:NULL])
                {
                    if ([scanner scanInteger:totalParts])
                    {
                        if ([scanner scanString:@")" intoString:NULL])
                        {
                            *numberLen = scanner.scanLocation - *numberPos;
                            break;
                        }
                    }
                    *totalParts = 0;
                }
            }
            *partNumber = 0;
        }
    }

    return partNumber > 0;
}

@interface ArticlePlaceholder : NSObject
{
    NSString *from;
    NSString *subject;
//    NSDate *date;
    NSString *references;
    NSUInteger completePartCount;
    NSMutableArray *parts;
}

@property(nonatomic, retain) NSString *from;
@property(nonatomic, retain) NSString *subject;
//@property(nonatomic, retain) NSDate *date;
@property(nonatomic, retain) NSString *references;
@property(nonatomic) NSUInteger completePartCount;
@property(nonatomic, retain) NSMutableArray *parts;

@end

@implementation ArticlePlaceholder

@synthesize from;
@synthesize subject;
//@synthesize date;
@synthesize references;
@synthesize completePartCount;
@synthesize parts;

- (id)init
{
    self = [super init];
    if (self)
    {
        parts = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return self;
}

@end

@implementation DownloadArticleOverviewsTask

- (id)initWithConnection:(NNConnection *)aConnection
    managedObjectContext:(NSManagedObjectContext *)aContext
                   group:(Group *)aGroup
                    mode:(DownloadArticleOverviewsTaskMode)mode
         maxArticleCount:(NSUInteger)aMaxArticleCount
{
    self = [super initWithConnection:aConnection];
    if (self)
    {
        group = aGroup;
        context = aContext;
        downloadMode = mode;
        maxArticleCount = aMaxArticleCount;

        // Core Data entity descriptions
        NSManagedObjectModel *model = context.persistentStoreCoordinator.managedObjectModel;
        articleEntity = [[model entitiesByName] objectForKey:@"Article"];
        articlePartEntity = [[model entitiesByName] objectForKey:@"ArticlePart"];

        placeholders = [[NSMutableDictionary alloc] initWithCapacity:1];
        encodedWordDecoder = [[EncodedWordDecoder alloc] init];
        
        linesRead = 0;
    }
    return self;
}

- (void)start
{
    [connection groupWithName:group.name];
}

- (void)groupSelected
{
    [connection overWithRange:articleRange];
}

#pragma mark -
#pragma mark Private Methods

- (void)addArticleWithOver:(NSString *)overviewLine
{
    // Scan for the various values in the overview
    NSScanner *scanner = [[NSScanner alloc] initWithString:overviewLine];
    
    scanner.charactersToBeSkipped = nil;
    
    // "Article number" field
    long long articleNumber;
    [scanner scanLongLong:&articleNumber];
    
    [scanner scanString:@"\t" intoString:NULL];
    
    // "Subject" field
    NSString *subject = nil;
    [scanner scanUpToString:@"\t" intoString:&subject];
    subject = [encodedWordDecoder decodeString:subject];
    
    [scanner scanString:@"\t" intoString:NULL];
    
    // "From" field
    NSString *from = nil;
    [scanner scanUpToString:@"\t" intoString:&from];
    from = [encodedWordDecoder decodeString:from];
    
    [scanner scanString:@"\t" intoString:NULL];
    
    // "Date" field
    NSString *string = nil;
    [scanner scanUpToString:@"\t" intoString:&string];
    NSDate *date = [Article dateWithString:string];
    
    [scanner scanString:@"\t" intoString:NULL];
    
    // "Message-ID" field
    NSString *messageId = nil;
    [scanner scanUpToString:@"\t" intoString:&messageId];
    
    [scanner scanString:@"\t" intoString:NULL];
    
    // "References" field
    NSString *references = nil;
    [scanner scanUpToString:@"\t" intoString:&references];
    
    [scanner scanString:@"\t" intoString:NULL];
    
    // "Bytes" field
    NSInteger bytes;
    [scanner scanInteger:&bytes];
    
    // What type of article are we adding?
    NSInteger partNumber;
    NSInteger totalParts;
    NSInteger numberPos;
    NSUInteger numberLen;
    PartNumber(subject, &partNumber, &totalParts, &numberPos, &numberLen);
    
    // TESTING
//    partNumber = 0;
//    totalParts = 0;
    
    // Edit the subject string
    if (partNumber > 0)
    {
        NSString *first = [subject substringToIndex:numberPos];
        NSString *second = [subject substringFromIndex:numberPos + numberLen];
        NSString *subjectEdit = [first stringByAppendingString:second];
        subjectEdit = [subjectEdit stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceCharacterSet]];
        subject = subjectEdit;
    }
    
    if (partNumber == 0 || (partNumber == 1 && totalParts == 1))
    {
        // Single part text or binary
        Article *article = [[Article alloc] initWithEntity:articleEntity
                            insertIntoManagedObjectContext:context];
        
        article.subject = subject;
        article.date = date;
        article.from = from;
        article.totalByteCount = [NSNumber numberWithInteger:bytes];
        article.completePartCount = [NSNumber numberWithInteger:1];
        article.references = references;
        
        ArticlePart *part = [[ArticlePart alloc] initWithEntity:articlePartEntity
                                 insertIntoManagedObjectContext:context];
        
        part.article = article;
        part.articleNumber = [NSNumber numberWithLongLong:articleNumber];
        part.date = date;
        part.partNumber = [NSNumber numberWithInteger:1];
        part.messageId = messageId;
        part.byteCount = [NSNumber numberWithInteger:bytes];
        
        // TODO Add this to a list to fault
    }
    else
    {
//        // TESTING
//        subject = [NSString stringWithFormat:@"MP %@", subject];

        // Multi part binary
        ArticlePart *part = [[ArticlePart alloc] initWithEntity:articlePartEntity
                                 insertIntoManagedObjectContext:context];
        
        part.articleNumber = [NSNumber numberWithLongLong:articleNumber];
        part.date = date;
        part.partNumber = [NSNumber numberWithInteger:partNumber];
        part.messageId = messageId;
        part.byteCount = [NSNumber numberWithInteger:bytes];
        
        // TODO Add this to a list to fault

        // Find if there is an existing placeholder, and create if necessary
        ArticlePlaceholder *placeholder = [placeholders objectForKey:subject];
        if (placeholder == nil)
        {
            placeholder = [[ArticlePlaceholder alloc] init];
            placeholder.subject = subject;
            placeholder.from = from;
            placeholder.references = references;
            placeholder.completePartCount = totalParts;

            [placeholders setObject:placeholder forKey:subject];
        }
        
        [placeholder.parts addObject:part];
    }
}

- (void)groupTogetherMultiparts
{
    // Find or create articles for multiparts
    for (ArticlePlaceholder *placeholder in placeholders.allValues)
    {
        // Does an article with this subject already exist?
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:articleEntity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"subject == %@", placeholder.subject];
        [request setPredicate:predicate];        
        
        NSError *error;
        NSArray *array = [context executeFetchRequest:request error:&error];
        if (array == nil)
        {
            // Deal with error...
        }
        
        Article *article = nil;
        NSUInteger totalByteCount = 0;
        if (array.count == 0)
        {
            // Create a new article
            article = [[Article alloc] initWithEntity:articleEntity
                       insertIntoManagedObjectContext:context];
            
            article.subject = placeholder.subject;
            article.from = placeholder.from;
            article.completePartCount = [NSNumber numberWithInteger:placeholder.completePartCount];
            article.references = placeholder.references;
            
        }
        else
        {
            // Use this existing article
            article = [array objectAtIndex:0];
            
            totalByteCount = article.totalByteCount.integerValue;
        }
        
        // Look through all the parts, to make sure we've set the article to
        // the earliest of the part dates
        NSDate *earliestDate = nil;
        
        for (ArticlePart *part in placeholder.parts)
        {
            [article addPartsObject:part];
            totalByteCount += part.byteCount.integerValue;
            
            // Note the earliest date of the parts
            if (earliestDate == nil || [earliestDate compare:part.date] == NSOrderedDescending)
                earliestDate = part.date;
        }
        article.date = earliestDate;
        
        article.totalByteCount = [NSNumber numberWithInteger:totalByteCount];
        
        NSAssert(article.date != nil, @"Article with nil date");
    }
    
    // Timestamp this update
    group.lastUpdate = [NSDate date];
    
    // Commit the changes to the store
    NSError *error = nil;
    if (![context save:&error])
    {
        NSLog(@"Error while saving\n%@",
              ([error localizedDescription] != nil)
              ? [error localizedDescription]
              : @"Unknown Error");
    }
}

- (NSRange)rangeOfLatestArticlesFromLowestArticleNumber:(long long)lowestArticleNumber
                                   highestArticleNumber:(long long)highestArticleNumber
{
//    long long lowestLoaded = group.lowestArticleNumber.longLongValue;
    long long highestLoaded = group.highestArticleNumber.longLongValue;
    if (highestLoaded < highestArticleNumber)
    {
        long long lowestNew;
        if (highestLoaded <= lowestArticleNumber)
            lowestNew = lowestArticleNumber;
        else
            lowestNew = highestLoaded + 1;

        NSLog(@"LATEST range: location = %lld, length = %lld", lowestNew, highestArticleNumber - lowestNew + 1);

        return NSMakeRange(lowestNew, highestArticleNumber - lowestNew + 1);
    }
    return NSMakeRange(highestArticleNumber, 0);
}

- (NSRange)rangeOfMoreArticlesFromLowestArticleNumber:(long long)lowestArticleNumber
//                                 highestArticleNumber:(long long)highestArticleNumber
{
    long long lowestLoaded = group.lowestArticleNumber.longLongValue;
//    long long highestLoaded = group.highestArticleNumber.longLongValue;
    if (lowestArticleNumber < lowestLoaded)
    {
        NSLog(@"MORE range: location = %lld, length = %lld", lowestArticleNumber, lowestLoaded - lowestArticleNumber);

        return NSMakeRange(lowestArticleNumber, lowestLoaded - lowestArticleNumber);
    }
    return NSMakeRange(lowestArticleNumber, 0);
}

- (NSRange)range:(NSRange)range limitedToMaxLength:(NSUInteger)maxLength
{
    // TODO: This needs checking -- we probably have an off-by-one error
    if (range.length > maxLength)
    {
        range.location += range.length - maxLength;
        range.length = maxLength;
    }

    NSLog(@"LIMITED range: location = %d, length = %d", range.location, range.length);
    
    return range;
}    

#pragma mark -
#pragma mark Notifications

- (void)bytesReceived:(NSNotification *)notification
{
    if (connection.responseCode == 224)
    {
        // Overview information follows
        LineIterator *lineIterator = [[LineIterator alloc] initWithData:connection.responseData];
//        NSMutableArray *articlesToFault = [[NSMutableArray alloc] initWithCapacity:1];
        
        while (!lineIterator.isAtEnd)
        {
            NSString *line = [lineIterator nextLine];
            if (lineIterator.partial)
            {
                // We have a partial line, so store it, and then leave this loop
                if (!partialLine)
                    partialLine = [[NSMutableString alloc] initWithString:line];
                else
                    [partialLine appendString:line];
                break;
            }
            
            // If we have a partial line from a previous run, form a complete
            // line with the newly retrieved line fragment
            if (partialLine)
            {
                [partialLine appendString:line];
                line = partialLine;
                partialLine = nil;
            }
            
            // Is this the end of the list?
            if (lineIterator.isAtEnd && [line isEqualToString:@".\r\n"])
                break;
            
            // Extract the group name from the line
            if (linesRead > 0)
            {
                [self addArticleWithOver:line];
            }
            
            ++linesRead;
        }

        // NOTE: The following commit is presently disabled so that groups
        // aren't saved if the task is cancelled.  The need to progressively
        // save articles is lessened since we will be loading smaller
        // amounts (default 1000) on the iPhone.
        
        // TODO: Reinstate this behaviour for the Mac version
        
//        // Commit the changes to the store
//        NSError *error = nil;
//        if (![context save:&error])
//        {
//            NSLog(@"Error while saving\n%@",
//                  ([error localizedDescription] != nil)
//                  ? [error localizedDescription]
//                  : @"Unknown Error");
//        }
//        
//        // Turn articles into faults to manage our memory use
//        for (Article *article in articlesToFault)
//            [context refreshObject:article mergeChanges:NO];
        
//        [articlesToFault release];
    }
}

- (void)commandResponded:(NSNotification *)notification
{
    NSUInteger responseCode = connection.responseCode;

    if (responseCode == 211)
    {
        // Group successfully selected
        
        // Scan the response string for the article numbers
        NSString *string = [[NSString alloc] initWithData:connection.responseData
                                                 encoding:NSUTF8StringEncoding];
        NSScanner *scanner = [[NSScanner alloc] initWithString:string];
        NSInteger response;
        long long number;
        long long low;
        long long high;
        NSString *name;
        [scanner scanInteger:&response];
        [scanner scanLongLong:&number];
        [scanner scanLongLong:&low];
        [scanner scanLongLong:&high];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet]
                                intoString:&name];

        NSRange range = NSMakeRange(0, 0);
        if (downloadMode == DownloadArticleOverviewsTaskLatest)
        {
            range = [self rangeOfLatestArticlesFromLowestArticleNumber:low
                                                  highestArticleNumber:high];
        }
        else if (downloadMode == DownloadArticleOverviewsTaskMore)
        {
            range = [self rangeOfMoreArticlesFromLowestArticleNumber:low];
        }
        articleRange = [self range:range limitedToMaxLength:maxArticleCount];
        
        // A note about articleRange.length.  A range length of 0 will never
        // come from interpreting a low and high point directly.  Even a low
        // and high point of 1 has a range length of 1.  This is why we subtract
        // 1 from NSMaxRange when we use it -- a length of 1, not 0, leaves the
        // high the same as the low
        // TODO: Create an "ArticleRange" struct, that takes into account this
        // understanding, and also uses long longs.
        if (articleRange.length > 0)
        {
            // Note the article numbers we're dealing with
            if (group.lowestArticleNumber.longLongValue == -1
                || group.lowestArticleNumber.longLongValue > articleRange.location)
            {
                group.lowestArticleNumber = [NSNumber numberWithLongLong:articleRange.location];
                NSLog(@"group.lowestArticleNumber = %lld", group.lowestArticleNumber.longLongValue);
            }

            if (group.highestArticleNumber.longLongValue < NSMaxRange(articleRange) - 1)
            {
                group.highestArticleNumber = [NSNumber numberWithLongLong:NSMaxRange(articleRange) - 1];
                NSLog(@"group.highestArticleNumber = %lld", group.highestArticleNumber.longLongValue);
            }

            [self scheduleSelector:@selector(groupSelected)];
        }
        else
        {
            // Timestamp this update
            group.lastUpdate = [NSDate date];
            [context save:NULL];

            // Notify
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:ArticleOverviewsDownloadedNotification
                              object:self];
        }
    }
    else if (responseCode == 411)
    {
        // No such newsgroup
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:NoSuchGroupNotification
                          object:self];
    }
    else if (responseCode == 224)
    {
        // Overview information follows
        
        [self groupTogetherMultiparts];
        
        // Notify
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:ArticleOverviewsDownloadedNotification
                          object:self];
    }
}

@end
