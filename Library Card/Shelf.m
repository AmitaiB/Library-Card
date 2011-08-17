//
//  Shelf.m
//  Library Card
//
//  Created by Will Barton on 8/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Shelf.h"
#import "Book.h"


@implementation Shelf

@dynamic name;
@dynamic books;

- (void)save {
    // Save the item=
    DEBUG(@"Saving Book: %@", [self description]);
    
    if (self.name == nil || [self.name isEqualToString:@""]) {
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
