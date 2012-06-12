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
- (void)performGoogleBooksQuery;
- (NSArray *)parseGoogleBooksQuery:(id)result;
@end


@implementation LCBookLookup

@synthesize bookSource = _bookSource;
@synthesize delegate = _delegate;

@synthesize queryString = _queryString;
@synthesize results = _results;
@synthesize numberOfResults = _numberOfResults;

@synthesize loading = _loading;

- (id)init {
    if (self = [super init]) {
        self.bookSource = kGoogleBooks;
    }
    return self;
}

- (void)performGoogleBooksQuery {
    
    _loading = YES;
    
    // Construct the query
    NSInteger startIndex = 0;
    if (self.results != nil && ([self.results count] < self.numberOfResults))
        startIndex = [self.results count];
    
    NSString * urlString = [NSString stringWithFormat:
                            @"https://www.googleapis.com/books/v1/volumes?key=%@&q=%@&startIndex=%d&maxResults=20", 
                            GoogleAPIKey, self.queryString, startIndex];
    NSURL * url = [NSURL URLWithString:urlString];
    
    DEBUG(@"Query String: %@", self.queryString);
    DEBUG(@"URL String: %@", urlString);
    DEBUG(@"Fetching URL %@", url);
    
    __block ASIHTTPRequest * request = [ASIHTTPRequest requestWithURL:url];
    
    [request setCompletionBlock:^{
        // Parse the resulting JSON
        SBJsonParser * parser = [[SBJsonParser alloc] init];
        id result = [parser objectWithString:request.responseString];
        if (!result) {
            NSLog(@"A JSON error occurred: %@", parser.error);
            [self.delegate bookLookup:self failedWithError:parser.error];
            return;
        }
        
        NSInteger totalItems = [((NSString *)[((NSDictionary *)result) objectForKey:@"totalItems"]) integerValue];
        _numberOfResults = totalItems;
        
        if (self.numberOfResults == 0) {
            NSError * error = [NSError errorWithDomain:LCBookLookupErrorDomain 
                                                  code:kBookNotFound 
                                              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        @"No books found", NSLocalizedDescriptionKey, nil]];
            [self.delegate bookLookup:self failedWithError:error];
            return;
        }
        
        // NSDictionary * bookInfo = [self parseGoogleBooksQuery:result];
        NSArray * booksInfo = [self parseGoogleBooksQuery:result];
        
        if (booksInfo == nil) {
            NSError * error = [NSError errorWithDomain:LCBookLookupErrorDomain 
                                                  code:kBookNotFound 
                                              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        @"No books found", NSLocalizedDescriptionKey, nil]];
            [self.delegate bookLookup:self failedWithError:error];
            return;
        }

        if (_results == nil) {
            // This was a new query
            _results = booksInfo;
        } else {
            // Add the new books to the results set.
            NSMutableArray * mutableResults = [_results mutableCopy];
            [mutableResults addObjectsFromArray:booksInfo];
            _results = [NSArray arrayWithArray:mutableResults];
        }

        [self.delegate bookLookupGotResults:self];
        _loading = NO;

        DEBUG(@"Found %d books", [self.results count]);
    }];
    
    [request setFailedBlock:^{
        NSError *error = [request error];
        
        NSLog(@"A HTTP error occurred: %@", error);
        
        [self.delegate bookLookup:self failedWithError:error];
        _loading = NO;

    }];
    
    [request startAsynchronous];

}

- (NSArray *)parseGoogleBooksQuery:(id)result {
       
    NSMutableArray * resultArray = [NSMutableArray array];
    
    for (NSDictionary * volumeDict in (NSArray *)[result objectForKey:@"items"]) {
    
        // Extract Google Books data
        // NSDictionary * volumeDict = (NSDictionary *)[((NSArray *)[result objectForKey:@"items"]) objectAtIndex:0];
        NSDictionary * volumeInfo = (NSDictionary *)[volumeDict objectForKey:@"volumeInfo"];
        
        NSMutableDictionary * bookInfo = [NSMutableDictionary dictionary];
        
        DEBUG(@"Got Book Info: %@", volumeDict);

        // Set Book attributes
        NSString * googleId = [volumeDict objectForKey:@"id"];
        if (googleId != nil)
            [bookInfo setObject:googleId forKey:@"googleId"];
        
        NSNumber * isEbook = [((NSDictionary *)[volumeDict objectForKey:@"saleInfo"]) objectForKey:@"isEbook"];
        if (isEbook == nil)
            [bookInfo setObject:isEbook forKey:@"isEbook"];
        
        NSString * title = [volumeInfo objectForKey:@"title"];
        if (title != nil)
            [bookInfo setObject:title forKey:@"title"];
        
        NSArray * authors = (NSArray *)[volumeInfo objectForKey:@"authors"];
        if (authors != nil)
            [bookInfo setObject:[authors componentsJoinedByString:@", "] forKey:@"authors"];
        
        NSString * publisher = [volumeInfo objectForKey:@"publisher"];
        if (publisher != nil)
            [bookInfo setObject:publisher forKey:@"publisher"];
                
        NSNumber * pages = [volumeInfo objectForKey:@"pageCount"];
        if (pages != nil)
            [bookInfo setObject:pages forKey:@"pages"];
        
        NSString * language = [volumeInfo objectForKey:@"language"];
        if (language != nil)
            [bookInfo setObject:language forKey:@"language"];
        
        NSString * thumbnailUrl = [((NSDictionary *)[volumeInfo objectForKey:@"imageLinks"]) objectForKey:@"thumbnail"];
        if (thumbnailUrl != nil) {
            // This is a hack to remove any possibility of curling in the thumbnail image.
            [bookInfo setObject:[thumbnailUrl stringByReplacingOccurrencesOfString:@"edge=curl" withString:@""] 
                         forKey:@"thumbnailUrl"]; 
        }
        
        NSArray * categories = (NSArray *)[volumeInfo objectForKey:@"categories"];
        if (categories != nil)
            [bookInfo setObject:[categories componentsJoinedByString:@", "] forKey:@"categories"];
        
        
        // Now the more complicated to extract attributes
        for (NSDictionary * isbnDict in (NSArray *)[volumeInfo objectForKey:@"industryIdentifiers"]) {
            if ([[isbnDict objectForKey:@"type"] isEqualToString:@"ISBN_10"])
                [bookInfo setObject:[isbnDict objectForKey:@"identifier"] forKey:@"isbn"];
            else if ([[isbnDict objectForKey:@"type"] isEqualToString:@"ISBN_13"])
                [bookInfo setObject:[isbnDict objectForKey:@"identifier"] forKey:@"isbn13"];
        }
        
        if ([volumeInfo objectForKey:@"publishedDate"] != nil) {
            // Published date might only include year, year and month, etc.
            @try {
                NSDateFormatter * formatter = [[NSDateFormatter alloc] init];

                if ([[volumeInfo objectForKey:@"publishedDate"] length] == 4)
                    formatter.dateFormat = @"yyyy";
                else if ([[volumeInfo objectForKey:@"publishedDate"] length] == 7)
                    formatter.dateFormat = @"yyyy-MM";
                else if ([[volumeInfo objectForKey:@"publishedDate"] length] == 10)
                    formatter.dateFormat = @"yyyy-MM-dd";

                [bookInfo setObject:[formatter dateFromString:[volumeInfo objectForKey:@"publishedDate"]] 
                             forKey:@"publishedDate"]; 

            }
            @catch (NSException *exception) {
                // Ignore the error, and just don't set publishedDate.
            }

        }
        
        [resultArray addObject:[NSDictionary dictionaryWithDictionary:bookInfo]];

    }
    
    return [NSArray arrayWithArray:resultArray];
}

- (void)downloadCoverImageForIndex:(NSInteger)index {
    
    if (index >= [self.results count])
        return;
    
    NSDictionary * bookInfo = [self.results objectAtIndex:index];
    NSString * isbn = [bookInfo objectForKey:@"isbn13"];
    NSString * imageUrl = [bookInfo objectForKey:@"thumbnailUrl"];
    
    if (isbn == nil || imageUrl == nil)
        return;
    
    ASIHTTPRequest * request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:imageUrl]];
    request.downloadDestinationPath = pathToCoverForISBN(isbn);
    
    [request setCompletionBlock:^{
        [self.delegate bookLookup:self downloadedCoverAtIndex:index];
    }];
    [request setFailedBlock:^{
        NSError *error = [request error];
        [self.delegate bookLookup:self failedWithError:error];
    }];
    [request startAsynchronous];
    
}

- (void)downloadCoverImage:(NSString *)imageUrl forISBN:(NSString *)isbn {
    
    ASIHTTPRequest * request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:imageUrl]];
    request.downloadDestinationPath = pathToCoverForISBN(isbn);
    
    [request setCompletionBlock:^{
        [self.delegate bookLookupDownloadedCover];
    }];
    [request setFailedBlock:^{
        NSError *error = [request error];
        [self.delegate bookLookup:self failedWithError:error];
    }];
    [request startAsynchronous];
    
}

- (void)lookupISBN:(NSString *)isbn {
    NSString * strippedISBN = [[isbn componentsSeparatedByCharactersInSet:
                                [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] 
                               componentsJoinedByString:@""];

    if (self.bookSource == kGoogleBooks) {
        NSString * queryString = [NSString stringWithFormat:@"isbn:%@", strippedISBN];
        _queryString = queryString;
        [self performGoogleBooksQuery];
    }
}

- (void)lookupBookInfo:(NSDictionary *)bookInfo {
    
    DEBUG(@"Looking up book with info: %@", bookInfo);
    
    // Reset properties
    _results = nil;
    _numberOfResults = 0;
    _queryString = nil;
    
    NSMutableArray * queryArray = [NSMutableArray array];
    
    if ([bookInfo objectForKey:@"title"] != nil && ![[bookInfo objectForKey:@"title"] isEqualToString:@""]) {
        NSString * escapedTitle = [[bookInfo objectForKey:@"title"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [queryArray addObject:[NSString stringWithFormat:@"intitle:%@", escapedTitle]];
    }
    
    if ([bookInfo objectForKey:@"authors"] != nil && ![[bookInfo objectForKey:@"authors"] isEqualToString:@""]) {
        NSString * escapedAuthors = [[bookInfo objectForKey:@"authors"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [queryArray addObject:[NSString stringWithFormat:@"inauthor:%@", escapedAuthors]];
    }
    
    if ([bookInfo objectForKey:@"publisher"] != nil && ![[bookInfo objectForKey:@"publisher"] isEqualToString:@""]) {
        NSString * escapedPublisher = [[bookInfo objectForKey:@"publisher"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [queryArray addObject:[NSString stringWithFormat:@"inpublisher:%@", escapedPublisher]];
    }
    
    if ([bookInfo objectForKey:@"isbn13"] != nil && ![[bookInfo objectForKey:@"isbn13"] isEqualToString:@""]) {
        NSString * strippedISBN = [[[bookInfo objectForKey:@"isbn13"] componentsSeparatedByCharactersInSet:
                                    [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] 
                                   componentsJoinedByString:@""];
        [queryArray addObject:[NSString stringWithFormat:@"isbn:%@", strippedISBN]];
    }
    
    if (self.bookSource == kGoogleBooks && [queryArray count] > 0) {
        NSString * queryString = [queryArray componentsJoinedByString:@"+"];
        _queryString = queryString;
        [self performGoogleBooksQuery];
    }

}

- (void)loadMoreResults {
    if ([self.results count] >= self.numberOfResults)
        return;
    
    // All we should have to do is this
    if (self.loading)
        return;
    
    [self performGoogleBooksQuery];
}

@end
