//
//  LCLabeledInputCell.h
//  Library Card
//
//  Created by Will Barton on 8/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LCLabeledInputCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel * titleLabel;
@property (nonatomic, retain) IBOutlet UITextField * textField;

@end
