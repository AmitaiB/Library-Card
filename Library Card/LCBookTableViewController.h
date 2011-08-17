//
//  LCBookTableViewController.h
//  Library Card
//
//  Created by Will Barton on 8/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCBarcodeScannerViewController.h"
#import "Book.h"

@interface LCBookTableViewController : UITableViewController <LCBarcodeScannerDelegate>


@property (nonatomic, retain) Book * book;

@property (nonatomic, retain) IBOutlet UIImageView * coverImageView;
@property (nonatomic, retain) IBOutlet UITextField * titleField;
@property (nonatomic, retain) IBOutlet UITextField * authorField;
@property (nonatomic, retain) IBOutlet UITextField * publisherField;
@property (nonatomic, retain) IBOutlet UITextField * dateField;
@property (nonatomic, retain) IBOutlet UITextField * locationField;



- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;

@end
