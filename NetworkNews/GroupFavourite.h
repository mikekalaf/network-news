//
//  GroupFavourite.h
//  Network News
//
//  Created by David Schweinsberg on 12/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Group;

@interface GroupFavourite :  NSManagedObject  
{
}

@property(nonatomic, retain) NSNumber *order;

@end
