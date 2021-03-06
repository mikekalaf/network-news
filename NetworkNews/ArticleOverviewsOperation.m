//
//  ArticleOverviewsOperation.m
//  NetworkNews
//
//  Created by David Schweinsberg on 10/03/13.
//  Copyright (c) 2013 David Schweinsberg. All rights reserved.
//

#import "ArticleOverviewsOperation.h"
#import "Article.h"
#import "ArticlePart.h"
#import "EncodedWordDecoder.h"
#import "GroupListing.h"
#import "GroupStore.h"
#import "LineIterator.h"
#import "NewsConnection.h"
#import "NewsConnectionPool.h"
#import "NewsResponse.h"

static BOOL PartNumber(NSString *subject, NSInteger *partNumber,
                       NSInteger *totalParts, NSInteger *numberPos,
                       NSUInteger *numberLen) {
  // Search for the pattern "(n/m)" in the subject string

  *partNumber = 0;
  *totalParts = 0;

  // Search backwards for the "("
  NSScanner *scanner = nil;
  for (NSInteger i = subject.length - 1; i >= 0; --i) {
    if ([subject characterAtIndex:i] == L'(') {
      *numberPos = i;

      if (scanner == nil)
        scanner = [[NSScanner alloc] initWithString:subject];

      scanner.scanLocation = i + 1;
      if ([scanner scanInteger:partNumber]) {
        if ([scanner scanString:@"/" intoString:NULL]) {
          if ([scanner scanInteger:totalParts]) {
            if ([scanner scanString:@")" intoString:NULL]) {
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

@interface _ArticlePlaceholder : NSObject

@property(nonatomic) NSString *from;
@property(nonatomic) NSString *subject;
@property(nonatomic) NSString *references;
@property(nonatomic) NSUInteger completePartCount;
@property(nonatomic, readonly) NSMutableArray *parts;

@end

@implementation _ArticlePlaceholder

- (instancetype)init {
  self = [super init];
  if (self) {
    _parts = [[NSMutableArray alloc] initWithCapacity:1];
  }
  return self;
}

@end

@interface ArticleOverviewsOperation () {
  NewsConnectionPool *_connectionPool;
  NSUInteger _maxArticleCount;
  ArticleRange _articleRange;
  NSMutableDictionary *_placeholders;
  EncodedWordDecoder *_encodedWordDecoder;
}

@end

@implementation ArticleOverviewsOperation

- (instancetype)initWithConnectionPool:(NewsConnectionPool *)connectionPool
                            groupStore:(GroupStore *)groupStore
                                  mode:(ArticleOverviewsMode)mode
                       maxArticleCount:(NSUInteger)maxArticleCount {
  self = [super init];
  if (self) {
    _connectionPool = connectionPool;
    _groupStore = groupStore;
    _mode = mode;
    _maxArticleCount = maxArticleCount;
    _placeholders = [[NSMutableDictionary alloc] initWithCapacity:1];
    _encodedWordDecoder = [[EncodedWordDecoder alloc] init];
  }
  return self;
}

- (void)main {
  @try {
    // We need a managed object context specifically for this thread
    GroupStore *concurrentGroupStore = [_groupStore concurrentGroupStore];

    BOOL retry = NO;
    do {
      _status = ArticleOverviewsUndefined;

      NewsConnection *newsConnection = [_connectionPool dequeueConnection];
      if (newsConnection == nil) {
        _status = ArticleOverviewsFailed;
        return;
      }

      // Select the newsgroup
      NewsResponse *response =
          [newsConnection groupWithName:_groupStore.groupName];

      if (response.statusCode == 211) {
        // Group successfully selected

        // Scan the response string for the article numbers
        NSString *string = [[NSString alloc] initWithData:response.data
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
        _availableArticles = [self rangeOfArticleNumberLow:low
                                         ArticleNumberHigh:high];

        ArticleRange storedRange = _groupStore.articleRange;

        if (_mode == ArticleOverviewsLatest) {
          if (high == ArticleRangeMax(storedRange) - 1) {
            NSLog(@"Already have latest articles");
            low = high + 1; // Force article range to have a length of zero
          }

          if (storedRange.length == 0) {
            low = MAX(high - (NSInteger)_maxArticleCount + 1, 0);
          } else {
            low = MAX(ArticleRangeMax(storedRange), low);
            high = MIN(low + _maxArticleCount, high);
          }
        } else if (_mode == ArticleOverviewsMore) {
          // Have we already downloaded all the articles?
          if ((NSInteger)storedRange.location - (NSInteger)_maxArticleCount <=
              low) {
            NSLog(@"Already have earliest articles");
            low = high + 1; // Force article range to have a length of zero
          } else {
            low = MAX((NSInteger)storedRange.location -
                          (NSInteger)_maxArticleCount,
                      low);
            high = MAX((NSInteger)storedRange.location, low);
          }
        }

        _articleRange = [self rangeOfArticleNumberLow:low
                                    ArticleNumberHigh:high];

        if (_articleRange.length == 0) {
          // This should just bump the update date
          [concurrentGroupStore save];

          // Nothing to do, so we're done
          _status = ArticleOverviewsComplete;
          [_connectionPool enqueueConnection:newsConnection];
          return;
        }

        retry = NO;
      } else if (response.statusCode == 411) {
        // No such newsgroup
        _status = ArticleOverviewsNoSuchGroup;
        [_connectionPool enqueueConnection:newsConnection];
        return;
      } else if (response.statusCode == 503) {
        // Connection has probably timed-out, so retry with a
        // new connection (if we haven't retried already)
        newsConnection = nil;
        retry = !retry;
      }

      [_connectionPool enqueueConnection:newsConnection];

    } while (retry);

    NewsConnection *newsConnection = [_connectionPool dequeueConnection];
    NewsResponse *response = [newsConnection overWithRange:_articleRange];
    [_connectionPool enqueueConnection:newsConnection];

    if (response.statusCode == 224) {
      NSUInteger linesRead = 0;

      // Overview information follows
      LineIterator *lineIterator =
          [[LineIterator alloc] initWithData:response.data];

      while (!lineIterator.isAtEnd) {
        NSString *line = [lineIterator nextLine];

        // Is this the end of the list?
        if (lineIterator.isAtEnd && [line isEqualToString:@".\r\n"])
          break;

        // Extract the article name from the line
        if (linesRead > 0) {
          [self addArticleWithOver:line toGroupStore:concurrentGroupStore];
        }

        ++linesRead;
      }

      [self groupTogetherMultipartsInGroupStore:concurrentGroupStore];

      // Commit the changes to the store
      [concurrentGroupStore save];

      _status = ArticleOverviewsComplete;
    }
  } @catch (NSException *exception) {
  } @finally {
  }
}

#pragma mark - Private Methods

- (ArticleRange)rangeOfArticleNumberLow:(long long)low
                      ArticleNumberHigh:(long long)high {
  if (low <= high)
    return ArticleRangeMake(low, high - low + 1);
  else
    return ArticleRangeMake(0, 0);
}

- (void)addArticleWithOver:(NSString *)overviewLine
              toGroupStore:(GroupStore *)groupStore {
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
  subject = [_encodedWordDecoder decodeString:subject];

  [scanner scanString:@"\t" intoString:NULL];

  // "From" field
  NSString *from = nil;
  [scanner scanUpToString:@"\t" intoString:&from];
  from = [_encodedWordDecoder decodeString:from];

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
  if (partNumber > 0) {
    NSString *first = [subject substringToIndex:numberPos];
    NSString *second = [subject substringFromIndex:numberPos + numberLen];
    NSString *subjectEdit = [first stringByAppendingString:second];
    subjectEdit = [subjectEdit
        stringByTrimmingCharactersInSet:[NSCharacterSet
                                            whitespaceCharacterSet]];
    subject = subjectEdit;
  }

  if (partNumber == 0 || (partNumber == 1 && totalParts == 1)) {
    NSEntityDescription *articleEntity =
        [NSEntityDescription entityForName:@"Article"
                    inManagedObjectContext:groupStore.managedObjectContext];
    NSEntityDescription *articlePartEntity =
        [NSEntityDescription entityForName:@"ArticlePart"
                    inManagedObjectContext:groupStore.managedObjectContext];

    // Single part text or binary
    Article *article =
        [[Article alloc] initWithEntity:articleEntity
            insertIntoManagedObjectContext:groupStore.managedObjectContext];

    article.subject = subject;
    article.date = date;
    article.from = from;
    article.totalByteCount = @(bytes);
    article.completePartCount = @1;
    article.references = references;

    ArticlePart *part =
        [[ArticlePart alloc] initWithEntity:articlePartEntity
             insertIntoManagedObjectContext:groupStore.managedObjectContext];

    part.article = article;
    part.articleNumber = @(articleNumber);
    part.date = date;
    part.partNumber = @1;
    part.messageId = messageId;
    part.byteCount = @(bytes);

    // TODO Add this to a list to fault
  } else {
    //        // TESTING
    //        subject = [NSString stringWithFormat:@"MP %@", subject];

    NSEntityDescription *articlePartEntity =
        [NSEntityDescription entityForName:@"ArticlePart"
                    inManagedObjectContext:groupStore.managedObjectContext];

    // Multi part binary
    ArticlePart *part =
        [[ArticlePart alloc] initWithEntity:articlePartEntity
             insertIntoManagedObjectContext:groupStore.managedObjectContext];

    part.articleNumber = @(articleNumber);
    part.date = date;
    part.partNumber = @(partNumber);
    part.messageId = messageId;
    part.byteCount = @(bytes);

    // TODO Add this to a list to fault

    // Find if there is an existing placeholder, and create if necessary
    _ArticlePlaceholder *placeholder = _placeholders[subject];
    if (placeholder == nil) {
      placeholder = [[_ArticlePlaceholder alloc] init];
      placeholder.subject = subject;
      placeholder.from = from;
      placeholder.references = references;
      placeholder.completePartCount = totalParts;

      _placeholders[subject] = placeholder;
    }

    [placeholder.parts addObject:part];
  }
}

- (void)groupTogetherMultipartsInGroupStore:(GroupStore *)groupStore {
  NSEntityDescription *articleEntity =
      [NSEntityDescription entityForName:@"Article"
                  inManagedObjectContext:groupStore.managedObjectContext];

  // Find or create articles for multiparts
  for (_ArticlePlaceholder *placeholder in _placeholders.allValues) {
    // Does an article with this subject already exist?

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = articleEntity;

    NSPredicate *predicate =
        [NSPredicate predicateWithFormat:@"subject == %@", placeholder.subject];
    request.predicate = predicate;

    NSError *error;
    NSArray *array =
        [groupStore.managedObjectContext executeFetchRequest:request
                                                       error:&error];
    if (array == nil) {
      // Deal with error...
    }

    Article *article = nil;
    NSUInteger totalByteCount = 0;
    if (array.count == 0) {
      // Create a new article
      article =
          [[Article alloc] initWithEntity:articleEntity
              insertIntoManagedObjectContext:groupStore.managedObjectContext];

      article.subject = placeholder.subject;
      article.from = placeholder.from;
      article.completePartCount = @(placeholder.completePartCount);
      article.references = placeholder.references;
    } else {
      // Use this existing article
      article = array[0];

      totalByteCount = article.totalByteCount.integerValue;
    }

    // Look through all the parts, to make sure we've set the article to
    // the earliest of the part dates
    NSDate *earliestDate = nil;

    for (ArticlePart *part in placeholder.parts) {
      [article addPartsObject:part];
      totalByteCount += part.byteCount.integerValue;

      // Note the earliest date of the parts
      if (earliestDate == nil ||
          [earliestDate compare:part.date] == NSOrderedDescending)
        earliestDate = part.date;
    }
    article.date = earliestDate;

    article.totalByteCount = @(totalByteCount);

    NSAssert([article date] != nil, @"Article with nil date");
  }
}

@end
