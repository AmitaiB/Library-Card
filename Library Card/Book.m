//
//  Book.m
//  Library Card
//
//  Created by Will Barton on 8/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Book.h"


@implementation Book

@dynamic title;
@dynamic authors;
@dynamic isbn;
@dynamic isbn13;
@dynamic publisher;
@dynamic issued;
@dynamic placeOfPublication;
@dynamic status;
@dynamic dateRead;
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
