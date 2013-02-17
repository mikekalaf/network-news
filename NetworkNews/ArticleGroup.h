//
//  ArticleGroup.h
//  Network News
//
//  Created by David Schweinsberg on 19/03/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Article;

@interface ArticleGroup : NSManagedObject
{
}

@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *type;
@property(nonatomic, retain) NSNumber *complete;
@property(nonatomic, retain) NSSet *articles;

@property(nonatomic, retain, readonly) NSString *shortName;

@end


@interface ArticleGroup (CoreDataGeneratedAccessors)
- (void)addArticlesObject:(Article *)value;
- (void)removeArticlesObject:(Article *)value;
- (void)addArticles:(NSSet *)value;
- (void)removeArticles:(NSSet *)value;

@end
