//
//  GroupNode.h
//  Network News
//
//  Created by David Schweinsberg on 5/02/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface GroupNode :  NSManagedObject  
{
}

@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSSet *children;
@property(nonatomic, retain) GroupNode *parent;

@end


@interface GroupNode (CoreDataGeneratedAccessors)
- (void)addChildrenObject:(GroupNode *)value;
- (void)removeChildrenObject:(GroupNode *)value;
- (void)addChildren:(NSSet *)value;
- (void)removeChildren:(NSSet *)value;

@end

