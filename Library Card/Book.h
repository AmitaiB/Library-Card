//
//  Book.h
//  Library Card
//
//  Created by Will Barton on 8/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Book : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * authors;
@property (nonatomic, retain) NSString * isbn;
@property (nonatomic, retain) NSString * isbn13;
@property (nonatomic, retain) NSString * publisher;
@property (nonatomic, retain) NSDate * issued;
@property (nonatomic, retain) NSString * placeOfPublication;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSDate * dateRead;
@property (nonatomic, retain) NSSet *shelves;
@end

@interface Book (CoreDataGeneratedAccessors)

- (void)addShelvesObject:(NSManagedObject *)value;
- (void)removeShelvesObject:(NSManagedObject *)value;
- (void)addShelves:(NSSet *)values;
- (void)removeShelves:(NSSet *)values;

- (void)save;

@end
