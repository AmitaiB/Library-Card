//
//  LCBookListTableViewController.h
//  Library Card
//
//  Created by Will Barton on 8/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// Generic parent class for all book list classes.


#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>


@interface LCBookListTableViewController : UITableViewController

@property (nonatomic, retain) NSPredicate * predicate;
@property (nonatomic, retain) NSString * cacheName;

@end
