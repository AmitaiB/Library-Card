//
//  LCCoverView.m
//  Library Card
//
//  Created by Will Barton on 8/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LCCoverView.h"

@implementation LCCoverView


@dynamic image;
@synthesize imageView = _imageView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    self.imageView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.imageView.layer.shadowOffset = CGSizeMake(1, 1);
    self.imageView.layer.shadowOpacity = 0.5;
    self.imageView.layer.shadowRadius = 5.0;

}

- (UIImage *)image {
    return self.imageView.image;
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    for (UITouch * touch in touches) {
        if (CGRectContainsPoint([self.imageView frame], [touch locationInView:self])) {
            NSLog(@"Touched in Cover Image");
        }
    }
    
    NSLog(@"Touches Began");
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	NSLog(@"touchesMoved");
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	NSLog(@"touchesEnded");
}

@end
