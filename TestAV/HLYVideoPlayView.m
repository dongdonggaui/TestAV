//
//  HLYVideoPlayView.m
//  TestAV
//
//  Created by huangluyang on 14-7-27.
//  Copyright (c) 2014年 huangluyang. All rights reserved.
//

#import "HLYVideoPlayView.h"

@implementation HLYVideoPlayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor blackColor];
}

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayer *)player
{
    return ((AVPlayerLayer *)self.layer).player;
}

- (void)setPlayer:(AVPlayer *)player
{
    [(AVPlayerLayer *)self.layer setPlayer:player];
}

@end
