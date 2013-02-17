//
//  Group.h
//  Network News
//
//  Created by David Schweinsberg on 5/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface Group : NSManagedObject
{
}

@property(nonatomic, retain) NSNumber *highestArticleNumber;
@property(nonatomic, retain) NSNumber *lowestArticleNumber;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSDate *lastUpdate;

@end
