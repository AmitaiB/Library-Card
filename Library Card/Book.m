//
//  Book.m
//  Library Card
//
//  Created by Will Barton on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Book.h"
#import "Shelf.h"

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
@dynamic shelves;

- (void)save {
    // Save the item=
    DEBUG(@"Saving Book: %@", [self description]);
    
    if (self.title == nil || [self.title isEqualToString:@""]) {
        DEBUG(@"Not Saving.");
        return;
    }
    
    NSError * error;
    if (![[self managedObjectContext] save:&error]) {
        DEBUG(@"Error: %@", error);
        DEBUG(@"Error Dict: %@", [error userInfo]);
        Alert(nil, @"There was an error saving the item", @"OK", nil);
        return;        
    }
    
    DEBUG(@"Item saved.");
}

@end

