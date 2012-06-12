//
//  LCBookGridViewCell.h
//  Library Card
//
//  Created by Will Barton on 10/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AQGridViewCell.h"

@interface LCBookGridViewCell : AQGridViewCell

@property (nonatomic, retain) IBOutlet UILabel * titleLabel;
@property (nonatomic, retain) IBOutlet UILabel * authorLabel;
@property (nonatomic, retain) IBOutlet UILabel * publishedLabel;
@property (nonatomic, retain) IBOutlet UIImageView * coverImageView;

@property (nonatomic, retain) UIImage * image;

@end
