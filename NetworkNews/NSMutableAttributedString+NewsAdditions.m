//
//  NSMutableAttributedString+NewsAdditions.m
//  Network News
//
//  Created by David Schweinsberg on 8/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "EncodedWordDecoder.h"
#import "NNHeaderEntry.h"
#import "NNHeaderParser.h"
#import "NNQuoteLevel.h"
#import "NNQuoteLevelParser.h"
#import "NSMutableAttributedString+NewsAdditions.h"
#import "Preferences.h"

#define LEVEL_INDENT 10.0

@implementation NSMutableAttributedString (NewsAdditions)

- (void)appendNewsHead:(NSArray *)entries {
  EncodedWordDecoder *encodedWordDecoder = [[EncodedWordDecoder alloc] init];
  //    UIFont *userFont = [UIFont systemFontOfSize:-1.0];
  UIFont *boldUserFont = [UIFont boldSystemFontOfSize:-1.0];

  // Header Field Name Attributes
  // - Bold
  // - Grey
  NSDictionary *nameAttributes = @{
    NSFontAttributeName : boldUserFont,
    NSForegroundColorAttributeName : [UIColor grayColor]
  };

  // Header Field Bold Value Attributes
  // - Bold
  NSDictionary *boldValueAttributes = @{NSFontAttributeName : boldUserFont};

  NSRange headerRange = NSMakeRange(self.length, 0);

  for (NNHeaderEntry *entry in entries) {
    // Does the entry have MIME encoded-word data?  If so, we need
    // to decode it
    NSString *entryValue = [encodedWordDecoder decodeString:entry.value];
    NSString *rawString =
        [NSString stringWithFormat:@"%@: %@\n", entry.name, entryValue];
    NSMutableAttributedString *attrString =
        [[NSMutableAttributedString alloc] initWithString:rawString];
    NSRange nameRange = NSMakeRange(0, entry.name.length + 1);
    NSRange valueRange = NSMakeRange(entry.name.length + 2, entryValue.length);
    [attrString setAttributes:nameAttributes range:nameRange];
    if ([entry.name isEqualToString:@"Subject"])
      [attrString setAttributes:boldValueAttributes range:valueRange];

    [self appendAttributedString:attrString];
    headerRange.length += attrString.length;
  }
}

- (void)appendShortNewsHead:(NSArray *)entries {
  [self appendNewsHead:[self shortHeadersFromHeaders:entries]];
}

- (void)appendBodyLineData:(NSData *)data
                quoteLevel:(NNQuoteLevel *)quoteLevel
               firstInBody:(BOOL)first {
  NSString *str = [[NSString alloc] initWithData:data
                                        encoding:NSUTF8StringEncoding];
  if (!str)
    str = [[NSString alloc] initWithData:data
                                encoding:NSISOLatin1StringEncoding];
  if (str) {
    if (!quoteLevel.flowed)
      str = [str stringByAppendingString:@"\n"];

    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
    ps.firstLineHeadIndent = LEVEL_INDENT * quoteLevel.level;
    ps.headIndent = LEVEL_INDENT * quoteLevel.level;
    if (first)
      ps.paragraphSpacingBefore = 20;
    NSDictionary *attributes = @{
      NSParagraphStyleAttributeName : ps,
      NSForegroundColorAttributeName :
          [Preferences colorForQuoteLevel:quoteLevel.level]
    };

    NSMutableAttributedString *attrStr =
        [[NSMutableAttributedString alloc] initWithString:str
                                               attributes:attributes];
    [self appendAttributedString:attrStr];
  }
}

- (NSArray *)shortHeadersFromHeaders:(NSArray *)entries {
  NSMutableArray *mutableArray = [NSMutableArray array];
  for (NNHeaderEntry *entry in entries) {
    if ([entry.name isEqualToString:@"From"] ||
        [entry.name isEqualToString:@"Newsgroups"] ||
        [entry.name isEqualToString:@"Subject"] ||
        [entry.name isEqualToString:@"Date"])
      [mutableArray addObject:entry];
  }
  return mutableArray;
}

- (void)appendNewsBody:(NSData *)data flowed:(BOOL)isFlowed {
  if (data == nil)
    return;

  NNQuoteLevelParser *qlp = [[NNQuoteLevelParser alloc] initWithData:data
                                                              flowed:isFlowed];
  NSArray *quoteLevels = qlp.quoteLevels;
  BOOL first = YES;
  for (NNQuoteLevel *quoteLevel in quoteLevels) {
    NSData *lineData = [data subdataWithRange:quoteLevel.range];
    [self appendBodyLineData:lineData quoteLevel:quoteLevel firstInBody:first];
    first = NO;
  }
}

@end
