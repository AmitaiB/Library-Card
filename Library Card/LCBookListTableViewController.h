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
#import "LCBookTableViewController.h"

@interface LCBookListTableViewController : UITableViewController <UISearchDisplayDelegate>

@property (strong, nonatomic) LCBookTableViewController * detailViewController;
@property (strong, nonatomic) NSManagedObjectContext * managedObjectContext;

@property (nonatomic, retain) IBOutlet UISegmentedControl * statusControl;
@property (nonatomic, retain) IBOutlet UIBarButtonItem * statusBarButtonItem;
@property (nonatomic, retain) NSPredicate * predicate;
@property (nonatomic, retain) NSString * cacheName;

@property (nonatomic) BOOL searching;

- (IBAction)addBook:(id)sender;

@end
