//
//  LCBookLookup.h
//  Library Card
//
//  Created by Will Barton on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const LCBookLookupErrorDomain;
typedef enum {
    kBookNotFound
} LCBookLookupError;

@class LCBookLookup;

@protocol LCBookLookupDelegate
@optional
- (void)bookLookupGotResults:(LCBookLookup *)bookLookup;
// There are two options for covers. For one-off lookups, you just need to respond to downloadedCover.
// For lookups that involve an array of results, respond to downloadedCoverAtIndex;
- (void)bookLookup:(LCBookLookup *)bookLookup downloadedCoverAtIndex:(NSInteger)index;
- (void)bookLookupDownloadedCover;
- (void)bookLookup:(LCBookLookup *)bookLookup failedWithError:(NSError *)error;
@end

@interface LCBookLookup : NSObject

@property (nonatomic, retain, readonly) NSString * queryString;
@property (nonatomic, retain) IBOutlet id <LCBookLookupDelegate> delegate;
@property (nonatomic) LCBookSource bookSource;

@property (nonatomic, readonly) NSInteger numberOfResults;
@property (nonatomic, retain, readonly) NSArray * results;

@property (nonatomic, readonly) BOOL loading;

// + (LCBookLookup *)sharedLookup;

- (void)lookupISBN:(NSString *)isbn;
- (void)lookupBookInfo:(NSDictionary *)bookInfo;
- (void)loadMoreResults;
- (void)downloadCoverImage:(NSString *)imageUrl forISBN:(NSString *)isbn;
- (void)downloadCoverImageForIndex:(NSInteger)index;

@end
