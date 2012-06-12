//
//  LCBookCell.h
//  Library Card
//
//  Created by Will Barton on 8/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LCBookCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel * titleLabel;
@property (nonatomic, retain) IBOutlet UILabel * authorLabel;
@property (nonatomic, retain) IBOutlet UILabel * publishedLabel;
@property (nonatomic, retain) IBOutlet UIImageView * coverImageView;
@end
