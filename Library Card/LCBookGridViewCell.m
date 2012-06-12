//
//  LCBookGridViewCell.m
//  Library Card
//
//  Created by Will Barton on 10/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LCBookGridViewCell.h"

@implementation LCBookGridViewCell


@synthesize titleLabel = _titleLabel;
@synthesize authorLabel = _authorLabel;
@synthesize publishedLabel = _publishedLabel;

@synthesize coverImageView = _coverImageView;

@dynamic image;

- (id) initWithFrame: (CGRect) frame reuseIdentifier: (NSString *) aReuseIdentifier
{
    self = [super initWithFrame: frame reuseIdentifier: aReuseIdentifier];
    if ( self == nil )
        return ( nil );
    
    self.coverImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.coverImageView];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont boldSystemFontOfSize: 12.0];
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumFontSize = 10.0;
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.opaque = NO;
    self.titleLabel.hidden = YES;
    [self.contentView addSubview:self.titleLabel];
    
    self.contentView.backgroundColor = [UIColor clearColor];
    self.contentView.opaque = NO;
    
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    
    return (self);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (CALayer *)glowSelectionLayer {
    return (self.coverImageView.layer );
}

- (UIImage *)image {
    return (self.coverImageView.image);
}

- (void)setImage:(UIImage *)anImage {
    self.coverImageView.image = anImage;
    self.coverImageView.layer.shadowColor = [UIColor redColor].CGColor;
    self.coverImageView.layer.shadowOffset = CGSizeMake(1, 1);
    self.coverImageView.layer.shadowOpacity = 1.0;
    self.coverImageView.layer.shadowRadius = 5.0;

    [self setNeedsLayout];
}

- (NSString *)title {
    return self.titleLabel.text;
}

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
    [self setNeedsLayout];
}

- (void)setHighlighted:(BOOL)value animated:(BOOL)animated {
    [super setHighlighted:value animated:animated];
    
    if (!self.isHighlighted) {
        self.coverImageView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.coverImageView.layer.shadowOffset = CGSizeMake(1, 1);
        self.coverImageView.layer.shadowOpacity = 1.0;
        self.coverImageView.layer.shadowRadius = 5.0;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize imageSize = self.coverImageView.image.size;
    CGRect bounds = self.contentView.bounds;
    CGRect insetBounds = CGRectInset(self.contentView.bounds, 10.0, 10.0);

    [self.titleLabel sizeToFit];
    // self.titleLabel.backgroundColor = [UIColor redColor];
    CGRect frame = self.titleLabel.frame;
    frame.size.width = MIN(frame.size.width, bounds.size.width);
    frame.origin.y = CGRectGetMaxY(bounds) - frame.size.height;
    frame.origin.x = floorf((bounds.size.width - frame.size.width) * 0.5);
    // NSLog(@"bounds: %f, frame: %f, x: %f", bounds.size.width, frame.size.width, frame.origin.x);
    self.titleLabel.frame = frame;
    
    // adjust the frame down for the image layout calculation
    bounds.size.height = frame.origin.y - bounds.origin.y;
    insetBounds.size.height = frame.origin.y - insetBounds.origin.y;
    
    if ((imageSize.width <= insetBounds.size.width) &&
        (imageSize.height <= insetBounds.size.height))
        return;
    
    // scale it down to fit
    CGFloat hRatio = insetBounds.size.width / imageSize.width;
    CGFloat vRatio = insetBounds.size.height / imageSize.height;
    CGFloat ratio = MIN(hRatio, vRatio);
    
    [self.coverImageView sizeToFit];

    frame = self.coverImageView.frame;
    frame.size.width = floorf(imageSize.width * ratio);
    frame.size.height = floorf(imageSize.height * ratio);
    frame.origin.x = floorf((bounds.size.width - frame.size.width) * 0.5);
    frame.origin.y = floorf((bounds.size.height - frame.size.height) * 0.5);
    self.coverImageView.frame = frame;
    
}

@end
