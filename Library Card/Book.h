//
//  Book.h
//  Library Card
//
//  Created by Will Barton on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


typedef enum {
    kReadingStatus,
    kToReadStatus,
    kReadStatus,
} LCBookStatus;

@class Shelf;

@interface Book : NSManagedObject

@property (nonatomic, retain) NSString * authors;
@property (nonatomic, retain) NSDate   * dateRead;
@property (nonatomic, retain) NSString * isbn;
@property (nonatomic, retain) NSString * isbn13;
@property (nonatomic, retain) NSDate   * publishedDate;
@property (nonatomic, retain) NSString * placeOfPublication;
@property (nonatomic, retain) NSString * publisher;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * pages;
@property (nonatomic, retain) NSString * categories;
@property (nonatomic, retain) NSNumber * rating;
@property (nonatomic, retain) NSString * thumbnailUrl;
@property (nonatomic, retain) NSString * language;
@property (nonatomic, retain) NSString * googleId;
@property (nonatomic, retain) NSNumber * bookmark;
@property (nonatomic, retain) NSNumber * isEbook;
@property (nonatomic, retain) NSString * review;
@property (nonatomic, retain) NSSet    * shelves;

@property (nonatomic, readonly) NSString * formattedPublishedDate;
@property (nonatomic, readonly) NSString * formattedDateRead;

@property (nonatomic, retain) UIImage *thumbnailImage;

@property (nonatomic, retain) NSManagedObject *image;

+ (NSString *)formattedDateFromDate:(NSDate*)date;
+ (Book *)bookFromInfo:(NSDictionary *)bookInfo;
- (void)setAttributesFromDict:(NSDictionary *)bookInfo;
- (void)save;

@end

@interface Book (CoreDataGeneratedAccessors)

- (void)addShelvesObject:(Shelf    * )value;
- (void)removeShelvesObject:(Shelf * )value;
- (void)addShelves:(NSSet          * )values;
- (void)removeShelves:(NSSet       * )values;

@end

@interface ImageToDataTransformer : NSValueTransformer {
}
@end

