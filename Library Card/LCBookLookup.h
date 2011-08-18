//
//  LCBookLookup.h
//  Library Card
//
//  Created by Will Barton on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LCBookLookup;

@protocol LCBookLookupDelegate
@optional
- (void)bookLookupFoundBook:(NSDictionary *)bookInfo;
- (void)bookLookupFailedWithError:(NSError *)error;
- (void)bookLookupDownloadedCover;
@end

@interface LCBookLookup : NSObject

@property (nonatomic, retain) IBOutlet id delegate;
@property (nonatomic) LCBookSource bookSource;

// + (LCBookLookup *)sharedLookup;

- (void)lookupISBN:(NSString *)isbn;
- (void)downloadCoverImage:(NSString *)imageUrl forISBN:(NSString *)isbn;

@end
