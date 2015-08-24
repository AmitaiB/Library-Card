//
//  Book.m
//  Library Card
//
//  Created by Will Barton on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Book.h"
#import "Shelf.h"
#import "LCAppDelegate.h"

@implementation Book

@dynamic authors;
@dynamic dateRead;
@dynamic isbn;
@dynamic isbn13;
@dynamic publishedDate;
@dynamic placeOfPublication;
@dynamic publisher;
@dynamic status;
@dynamic title;
@dynamic pages;
@dynamic categories;
@dynamic rating;
@dynamic thumbnailUrl;
@dynamic language;
@dynamic googleId;
@dynamic isEbook;
@dynamic bookmark;
@dynamic review;
@dynamic shelves;

@dynamic thumbnailImage;
@dynamic image;

@dynamic formattedDateRead;
@dynamic formattedPublishedDate;

+ (Book *)bookFromInfo:(NSDictionary *)bookInfo {
    
    NSManagedObjectContext * managedObjectContext = ((LCAppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
    Book * book = [NSEntityDescription insertNewObjectForEntityForName:@"Book" 
                                         inManagedObjectContext:managedObjectContext];
    [book setAttributesFromDict:bookInfo];
    return book;
}

- (void)setAttributesFromDict:(NSDictionary *)bookInfo {
    
    // Set Book attributes
    self.googleId      = [bookInfo objectForKey:@"googleId"];
    self.title         = [bookInfo objectForKey:@"title"];
    self.authors       = [bookInfo objectForKey:@"authors"];
    self.publisher     = [bookInfo objectForKey:@"publisher"];
    self.pages         = [bookInfo objectForKey:@"pages"];
    self.language      = [bookInfo objectForKey:@"language"];
    self.thumbnailUrl  = [bookInfo objectForKey:@"thumbnailUrl"];
    self.categories    = [bookInfo objectForKey:@"categories"];
    self.isbn          = [bookInfo objectForKey:@"isbn"];
    self.isbn13        = [bookInfo objectForKey:@"isbn13"];
    self.publishedDate = [bookInfo objectForKey:@"publishedDate"];
}

- (NSString *)formattedDateRead {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateStyle        = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle        = NSDateFormatterNoStyle;

    NSString * formattedDateString = [dateFormatter stringFromDate:self.dateRead];
    
    return formattedDateString;
}

- (NSString *)formattedPublishedDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    
    NSString * formattedDateString = [dateFormatter stringFromDate:self.publishedDate];
    
    return formattedDateString;
}

- (void)save {
    // Save the item=
    DEBUG(@"Saving Book: %@", [self description]);
    
    if (self.title == nil || [self.title isEqualToString:@""]) {
        DEBUG(@"Not Saving.");
        return;
    }
    
    NSManagedObjectContext * moc = self.managedObjectContext;
    NSError * error;
    DEBUG(@"PSC: %@", [[moc persistentStoreCoordinator] persistentStores]);
    if ([[[moc persistentStoreCoordinator] persistentStores] count] > 0) {
        DEBUG(@"More than one persistent store");
        if (![moc save:&error]) {
            DEBUG(@"Error: %@", error);
            DEBUG(@"Error Dict: %@", [error userInfo]);
            Alert(nil, @"There was an error saving the item", @"OK", nil);
            return;        
        }
    }
    
    DEBUG(@"Item saved.");
}

@end

@implementation ImageToDataTransformer

+ (BOOL)allowsReverseTransformation {
	return YES;
}

+ (Class)transformedValueClass {
	return [NSData class];
}

- (id)transformedValue:(id)value {
    // for our smaller views this uses much less data and makes for faster syncing
    // multi-media asset quality should account for sync performance and storage
	NSData *data = UIImageJPEGRepresentation(value, 0.1);
	return data;
}


- (id)reverseTransformedValue:(id)value {
	UIImage * uiImage = [[UIImage alloc] initWithData:value];
	return uiImage;
}

@end
