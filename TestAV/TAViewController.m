//
//  TAViewController.m
//  TestAV
//
//  Created by huangluyang on 14-7-26.
//  Copyright (c) 2014年 huangluyang. All rights reserved.
//

#import "TAViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "HLYImageVideoMaker.h"
#import "HLYVideoPlayView.h"

@interface TAViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet HLYVideoPlayView *videoView;
@property (weak, nonatomic) IBOutlet UIButton *pickerButton;
@property (weak, nonatomic) IBOutlet UILabel *pathLabel;

@property (nonatomic, strong) NSString *videoPath;
@property (nonatomic, strong) UIImage *pickerdImage;

@end

@implementation TAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.playButton.enabled = NO;
    self.button.enabled = NO;
    [self.button addTarget:self action:@selector(convertButtonDidTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.playButton addTarget:self action:@selector(playeButtonDidTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.pickerButton addTarget:self action:@selector(pickerButtonDidTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - private
- (void)convertButtonDidTapped:(UIButton *)sender
{
    [self.textField resignFirstResponder];
    
    if (self.textField.text.length == 0) {
        return;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths lastObject];
    NSString *imageCache = [cachesDirectory stringByAppendingPathComponent:@"HWDImageCache"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:imageCache]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:imageCache withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    imageCache = [imageCache stringByAppendingString:[NSString stringWithFormat:@"/%@.mp4", self.textField.text]];
    NSLog(@"path --> %@", imageCache);
    
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"JPG"];
    
    __weak TAViewController *safeSelf = self;
    [HLYImageVideoMaker writeImage:self.pickerdImage withFps:30 duration:5 startRect:CGRectMake(0, 0, 560, 420) endRect:CGRectMake(20, 460, 560, 420) toVideo:imageCache withSize:CGSizeMake(640, 480) complete:^(NSString *path) {
        safeSelf.playButton.enabled = YES;
        safeSelf.videoPath = path;
    }];
}

- (void)playeButtonDidTapped:(UIButton *)sender
{
    NSURL *url = [[NSURL alloc] initFileURLWithPath:self.videoPath];
    NSLog(@"url --> %@", url);
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
    [self.videoView setPlayer:player];
    
    [self.videoView.player play];
}

- (void)pickerButtonDidTapped:(UIButton *)sender
{
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.delegate = self;
    [self presentViewController:ipc animated:YES completion:nil];
}

#pragma mark -
#pragma mark - ipc delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.pickerdImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSURL *url = [info objectForKey:UIImagePickerControllerReferenceURL];
    if (url) {
        self.pathLabel.text = url.absoluteString;
    }
    self.button.enabled = self.pickerdImage != nil;
}

@end
