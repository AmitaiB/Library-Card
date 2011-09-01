//
//  LCBookLookup.m
//  Library Card
//
//  Created by Will Barton on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LCBookLookup.h"
#import "SBJson.h"
#import "ASIHTTPRequest.h"
#import "LCAppDelegate.h"

NSString * const LCBookLookupErrorDomain = @"LCBookLookupErrorDomain";

@interface LCBookLookup (Private)
- (void)googleBooksWithQuery:(NSString *)queryString;
- (NSDictionary *)parseGoogleBooksQuery:(id)result;
@end


@implementation LCBookLookup

@synthesize bookSource = _bookSource;
@synthesize delegate = _delegate;

/*
+ (LCBookLookup *)sharedLookup {
    static LCBookLookup *sharedSingleton;
    
    @synchronized(self) {
        if (!sharedSingleton)
            sharedSingleton = [[LCBookLookup alloc] init];
        
        return sharedSingleton;
    }
}
*/

- (id)init {
    if (self = [super init]) {
        self.bookSource = kGoogleBooks;
    }
    return self;
}

- (void)googleBooksWithQuery:(NSString *)queryString {
    NSString * urlString = [NSString stringWithFormat:
                            @"https://www.googleapis.com/books/v1/volumes?key=%@&q=%@", 
                            GoogleAPIKey, queryString];
    NSURL * url = [NSURL URLWithString:urlString];
    
    NSLog(@"Fetching URL %@", url);
    
    __block ASIHTTPRequest * request = [ASIHTTPRequest requestWithURL:url];
    
    [request setCompletionBlock:^{
        // Parse the resulting JSON
        SBJsonParser * parser = [[SBJsonParser alloc] init];
        id result = [parser objectWithString:request.responseString];
        if (!result) {
            NSLog(@"A JSON error occurred: %@", parser.error);
            [self.delegate bookLookupFailedWithError:parser.error];
            return;
        }
        
        NSInteger totalItems = [((NSString *)[((NSDictionary *)result) objectForKey:@"totalItems"]) integerValue];
        if (totalItems == 0) {
            NSLog(@"Total items is 0. Book was not found.");
            NSError * error = [NSError errorWithDomain:LCBookLookupErrorDomain 
                                                  code:kBookNotFound 
                                              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        @"Book not found", NSLocalizedDescriptionKey, nil]];
            [self.delegate bookLookupFailedWithError:error];
            return;
        }
        
        NSDictionary * bookInfo = [self parseGoogleBooksQuery:result];
        
        if (bookInfo == nil) {
            NSLog(@"Book info was nil.");
            NSError * error = [NSError errorWithDomain:LCBookLookupErrorDomain 
                                                  code:kBookNotFound 
                                              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        @"Book not found", NSLocalizedDescriptionKey, nil]];
            [self.delegate bookLookupFailedWithError:error];
            return;
        }
        
        [self.delegate bookLookupFoundBook:bookInfo];
    }];
    
    [request setFailedBlock:^{
        NSError *error = [request error];
        
        NSLog(@"A HTTP error occurred: %@", error);
        
        [self.delegate bookLookupFailedWithError:error];
    }];
    
    [request startAsynchronous];

}

- (NSDictionary *)parseGoogleBooksQuery:(id)result {
        
    
    // Extract Google Books data
    NSDictionary * volumeDict = (NSDictionary *)[((NSArray *)[result objectForKey:@"items"]) objectAtIndex:0];
    NSDictionary * volumeInfo = (NSDictionary *)[volumeDict objectForKey:@"volumeInfo"];
    
    NSMutableDictionary * bookInfo = [NSMutableDictionary dictionary];
    
    
    NSLog(@"Got Book Info: %@", volumeDict);
    
    // Set Book attributes
    [bookInfo setObject:[volumeDict objectForKey:@"id"] 
                 forKey:@"googleId"];
    [bookInfo setObject:[volumeInfo objectForKey:@"title"] 
                 forKey:@"title"];
    [bookInfo setObject:[((NSArray *)[volumeInfo objectForKey:@"authors"]) componentsJoinedByString:@", "] 
                 forKey:@"authors"];
    [bookInfo setObject:[volumeInfo objectForKey:@"publisher"]
                 forKey:@"publisher"];
    [bookInfo setObject:[NSNumber numberWithInt:[((NSString *)[volumeInfo objectForKey:@"pageCount"]) intValue]] 
                 forKey:@"pages"];
    [bookInfo setObject:[volumeInfo objectForKey:@"language"] 
                 forKey:@"language"];
    [bookInfo setObject:[((NSDictionary *)[volumeInfo objectForKey:@"imageLinks"]) objectForKey:@"thumbnail"] 
                 forKey:@"thumbnailUrl"]; 
    [bookInfo setObject:[((NSArray *)[volumeInfo objectForKey:@"categories"]) componentsJoinedByString:@", "]
                 forKey:@"categories"];
    
    // This is a hack to remove any possibility of curling in the thumbnail image.
    NSString * thumbnailUrl = [bookInfo objectForKey:@"thumbnailUrl"];
    [bookInfo setObject:[thumbnailUrl stringByReplacingOccurrencesOfString:@"edge=curl" withString:@""] 
                 forKey:@"thumbnailUrl"]; 

    // Now the more complicated to extract attributes
    for (NSDictionary * isbnDict in (NSArray *)[volumeInfo objectForKey:@"industryIdentifiers"]) {
        if ([[isbnDict objectForKey:@"type"] isEqualToString:@"ISBN_10"])
            [bookInfo setObject:[isbnDict objectForKey:@"identifier"] forKey:@"isbn"];
        else if ([[isbnDict objectForKey:@"type"] isEqualToString:@"ISBN_13"])
            [bookInfo setObject:[isbnDict objectForKey:@"identifier"] forKey:@"isbn13"];
    }
    
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    [bookInfo setObject:[formatter dateFromString:[volumeInfo objectForKey:@"publishedDate"]] 
                 forKey:@"publishedDate"]; 
         
    return [NSDictionary dictionaryWithDictionary:bookInfo];
}

- (void)downloadCoverImage:(NSString *)imageUrl forISBN:(NSString *)isbn {
    
    ASIHTTPRequest * request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:imageUrl]];
    request.downloadDestinationPath = pathToCoverForISBN(isbn);
    
    [request setCompletionBlock:^{
        [self.delegate bookLookupDownloadedCover];
    }];
    [request setFailedBlock:^{
        NSError *error = [request error];
        [self.delegate bookLookupFailedWithError:error];
    }];
    [request startAsynchronous];
    
}

- (void)lookupISBN:(NSString *)isbn {
    NSString * strippedISBN = [[isbn componentsSeparatedByCharactersInSet:
                                [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] 
                               componentsJoinedByString:@""];

    if (self.bookSource == kGoogleBooks) {
        NSString * queryString = [NSString stringWithFormat:@"isbn+%@", strippedISBN];
        [self googleBooksWithQuery:queryString];
    }
}

@end
