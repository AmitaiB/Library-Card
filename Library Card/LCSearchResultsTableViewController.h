//
//  LCSearchResultsTableViewController.h
//  Library Card
//
//  Created by Will Barton on 9/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCBookLookup.h"

@class LCSearchResultsTableViewController;

@protocol LCSearchResultsDelegate
@optional
- (void)searchResultsControllerSelectedBook:(NSDictionary *)bookInfo;
- (void)searchResultsControllerCanceled;
@end

@interface LCSearchResultsTableViewController : UITableViewController <LCBookLookupDelegate>

@property (nonatomic, retain) LCBookLookup * bookLookup;
@property (nonatomic, retain) id <LCSearchResultsDelegate> delegate;

- (IBAction)cancel:(id)sender;

@end
