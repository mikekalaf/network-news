//
//  NSMutableAttributedString+NewsAdditions.m
//  Network News
//
//  Created by David Schweinsberg on 8/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NSMutableAttributedString+NewsAdditions.h"
#import "NNHeaderParser.h"
#import "NNHeaderEntry.h"
#import "NNQuoteLevelParser.h"
#import "NNQuoteLevel.h"
#import "Preferences.h"
#import "EncodedWordDecoder.h"

#define LEVEL_INDENT 20.0

@implementation NSMutableAttributedString (NewsAdditions)

- (void)appendNewsHead:(NSArray *)entries
{
    EncodedWordDecoder *encodedWordDecoder = [[EncodedWordDecoder alloc] init];
    UIFont *userFont = [UIFont systemFontOfSize:-1.0];
    UIFont *boldUserFont = [UIFont boldSystemFontOfSize:-1.0];
    
    // Header Field Name Attributes
    // - Bold
    // - Grey
    NSDictionary *nameAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    boldUserFont, NSFontAttributeName,
                                    [UIColor grayColor], NSForegroundColorAttributeName,
                                    nil];
    
    // Header Field Bold Value Attributes
    // - Bold
    NSDictionary *boldValueAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                         boldUserFont, NSFontAttributeName,
                                         nil];

    NSRange headerRange = NSMakeRange(self.length, 0);

    for (NNHeaderEntry *entry in entries)
    {
        // Does the entry have MIME encoded-word data?  If so, we need
        // to decode it
        NSString *entryValue = [encodedWordDecoder decodeString:entry.value];
        
        NSString *rawString = [NSString stringWithFormat:@"\t%@:\t%@\n",
                               entry.name,
                               entryValue];
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:rawString];
        NSRange nameRange = NSMakeRange(1, entry.name.length + 1);
        NSRange valueRange = NSMakeRange(entry.name.length + 3, entryValue.length);
        [attrString setAttributes:nameAttributes range:nameRange];
        if ([entry.name isEqualToString:@"Subject"])
            [attrString setAttributes:boldValueAttributes range:valueRange];
        
        [self appendAttributedString:attrString];
        headerRange.length += attrString.length;
    }

    // Add some space after the header
    NSAttributedString *space = [[NSAttributedString alloc] initWithString:@"\n\n"];
    [self appendAttributedString:space];
    headerRange.length += 2;
    
    // Header Paragraph Attributes
    // - Two tab stops, the first with right-aligned text
//    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
//    NSArray *headerTabStops = [NSArray arrayWithObjects:
//                               [[NSTextTab alloc] initWithType:NSRightTabStopType location:85.0],
//                               [[NSTextTab alloc] initWithType:NSLeftTabStopType location:90.0],
////                               [[[NSTextTab alloc] initWithType:NSRightTabStopType location:155.0] autorelease],
////                               [[[NSTextTab alloc] initWithType:NSLeftTabStopType location:160.0] autorelease],
//                               nil];
//    [ps setTabStops:headerTabStops];
////    [ps setParagraphSpacingBefore:20.0];
//
//    NSDictionary *paragraphAttributes = [NSDictionary dictionaryWithObject:ps
//                                                                    forKey:NSParagraphStyleAttributeName];
//    [self addAttributes:paragraphAttributes range:headerRange];
}

- (void)appendShortNewsHead:(NSArray *)entries
{
    [self appendNewsHead:[self shortHeadersFromHeaders:entries]];
}

- (void)appendBodyData:(NSData *)data quoteLevel:(NSUInteger)level
{
    NSString *str = [[NSString alloc] initWithData:data
                                          encoding:NSUTF8StringEncoding];
    if (!str)
        str = [[NSString alloc] initWithData:data
                                    encoding:NSISOLatin1StringEncoding];
    if (str)
    {
        //NSLog(@"Level: %d {%@}", level, str);

        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        ps.firstLineHeadIndent = LEVEL_INDENT * level;
        ps.headIndent = LEVEL_INDENT * level;
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    ps, NSParagraphStyleAttributeName,
                                    [Preferences colorForQuoteLevel:level], NSForegroundColorAttributeName,
                                    nil];

        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:str
                                                                                    attributes:attributes];
        [self appendAttributedString:attrStr];
    }
}

- (NSArray *)shortHeadersFromHeaders:(NSArray *)entries
{
    NSMutableArray *mutableArray = [NSMutableArray array];
    for (NNHeaderEntry *entry in entries)
    {
        if ([entry.name isEqualToString:@"From"]
            || [entry.name isEqualToString:@"Newsgroups"]
            || [entry.name isEqualToString:@"Subject"]
            || [entry.name isEqualToString:@"Date"])
            [mutableArray addObject:entry];
    }
    return mutableArray;
}

/*
- (void)appendNewsData:(NSData *)data
{
    if (data == nil)
        return;

    // Append the visible headers
    NNHeaderParser *hp = [[NNHeaderParser alloc] initWithData:data];
    NSArray *entries = [self shortHeadersFromHeaders:hp.entries];
    [self appendHeaders:entries];
    
    // Append the body
    NSRange bodyRange = NSMakeRange(hp.length, data.length - hp.length);
    NSData *bodyData = [data subdataWithRange:bodyRange];
    
    NNQuoteLevelParser *qlp = [[NNQuoteLevelParser alloc] initWithData:bodyData];
    NSArray *quoteLevels = qlp.quoteLevels;
    [qlp release];
    
    for (NNQuoteLevel *quoteLevel in quoteLevels)
    {
        NSData *lineData = [bodyData subdataWithRange:quoteLevel.range];
        [self appendBodyData:lineData quoteLevel:quoteLevel.level];
    }

    [hp release];
}
*/

- (void)appendNewsBody:(NSData *)data flowed:(BOOL)isFlowed
{
    if (data == nil)
        return;

    NNQuoteLevelParser *qlp = [[NNQuoteLevelParser alloc] initWithData:data
                                                                flowed:isFlowed];
    NSArray *quoteLevels = qlp.quoteLevels;

    for (NNQuoteLevel *quoteLevel in quoteLevels)
    {
        NSData *lineData = [data subdataWithRange:quoteLevel.range];
        [self appendBodyData:lineData quoteLevel:quoteLevel.level];
    }
}

@end
